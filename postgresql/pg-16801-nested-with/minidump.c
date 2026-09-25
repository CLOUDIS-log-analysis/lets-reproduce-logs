#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <execinfo.h>
#include <ucontext.h>
#include <fcntl.h>
#include <unistd.h>

#define MAX_FRAMES 64
#define ALT_STACK_SIZE (64 * 1024)   // sigaltstack용 별도 스택 (SIGSTKSZ 대신 고정값 사용 - 이식성)
#define WATCHDOG_SECONDS 5           // 핸들러가 이 시간 넘게 멈추면 강제 종료

static char alt_stack[ALT_STACK_SIZE];

// write()로 직접 씀 (printf류는 내부에서 malloc 가능성 있어 회피)
static void wstr(int fd, const char *s) { write(fd, s, strlen(s)); }

// 크래시 시 커널이 호출하는 함수
static void on_crash(int sig, siginfo_t *info, void *ucontext_raw) {
    // [보완 2] 워치독: 힙이 심하게 손상돼 아래 코드가 멈추더라도,
    // WATCHDOG_SECONDS 후 SIGALRM 기본 동작(프로세스 종료)이 대신 처리해줌
    alarm(WATCHDOG_SECONDS);

    // PID로 구분 (postgres는 커넥션마다 별도 프로세스)
    char path[256];
    snprintf(path, sizeof(path), "/var/log/postgresql/minidump-%d.txt", getpid());
    int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0666);
    if (fd < 0) { signal(sig, SIG_DFL); raise(sig); return; }

    char buf[512];
    int n = snprintf(buf, sizeof(buf),
        "=== MINIDUMP ===\nsignal=%d (%s)\npid=%d\nfaulting_address=%p\n",
        sig, strsignal(sig), getpid(), info->si_addr);
    write(fd, buf, n);

    // 크래시 순간 CPU 레지스터 스냅샷 (x86_64 전용)
    ucontext_t *uc = (ucontext_t *)ucontext_raw;
#if defined(__x86_64__)
    n = snprintf(buf, sizeof(buf),
        "RIP=%016llx RSP=%016llx RBP=%016llx\nRAX=%016llx RBX=%016llx RCX=%016llx RDX=%016llx\n",
        (unsigned long long)uc->uc_mcontext.gregs[REG_RIP],
        (unsigned long long)uc->uc_mcontext.gregs[REG_RSP],
        (unsigned long long)uc->uc_mcontext.gregs[REG_RBP],
        (unsigned long long)uc->uc_mcontext.gregs[REG_RAX],
        (unsigned long long)uc->uc_mcontext.gregs[REG_RBX],
        (unsigned long long)uc->uc_mcontext.gregs[REG_RCX],
        (unsigned long long)uc->uc_mcontext.gregs[REG_RDX]);
    write(fd, buf, n);
#endif

    // 콜스택 -> 함수명 변환 후 파일에 기록
    // (backtrace() 자체는 [보완 1]에서 미리 예열해뒀으므로 여기서 malloc 재호출 없음)
    wstr(fd, "\n=== BACKTRACE ===\n");
    void *frames[MAX_FRAMES];
    int nframes = backtrace(frames, MAX_FRAMES);
    backtrace_symbols_fd(frames, nframes, fd);

    // 주소만 나올 경우 addr2line으로 역산하기 위한 모듈 정보
    wstr(fd, "\n=== MODULES (/proc/self/maps) ===\n");
    int mfd = open("/proc/self/maps", O_RDONLY);
    if (mfd >= 0) {
        char mbuf[4096];
        ssize_t r;
        while ((r = read(mfd, mbuf, sizeof(mbuf))) > 0) write(fd, mbuf, r);
        close(mfd);
    }
    close(fd);

    // 정상적으로 다 끝났으면 워치독 해제
    alarm(0);

    // 기본 동작 복원 후 재시그널 -> postgres 자체 로그 기록 + 실제 종료 보장
    signal(sig, SIG_DFL);
    raise(sig);
}

// .so 로드 시 자동 실행 -> 소스 수정 없이 시그널 핸들러 등록
__attribute__((constructor))
static void install_handler(void) {
    // [보완 3] 별도 안전 스택 등록: 스택 오버플로우로 크래시 난 경우에도
    // 핸들러가 망가진 스택이 아니라 이 안전한 공간에서 실행되게 함
    stack_t ss;
    ss.ss_sp = alt_stack;
    ss.ss_size = ALT_STACK_SIZE;
    ss.ss_flags = 0;
    sigaltstack(&ss, NULL);

    // [보완 1] backtrace() 예열: 힙이 정상인 지금 미리 한 번 호출해서
    // 내부 malloc 기반 초기화를 끝내둠 -> 실제 크래시 시엔 malloc 재호출 없음
    void *warmup[1];
    backtrace(warmup, 1);

    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = on_crash;
    // SA_ONSTACK: 등록해둔 안전 스택(alt_stack)에서 핸들러 실행
    sa.sa_flags = SA_SIGINFO | SA_RESTART | SA_ONSTACK;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGSEGV, &sa, NULL);
    sigaction(SIGABRT, &sa, NULL);
    sigaction(SIGBUS, &sa, NULL);
    sigaction(SIGILL, &sa, NULL);
}
