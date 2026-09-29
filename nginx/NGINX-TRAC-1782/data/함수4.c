static ngx_int_t
ngx_http_upstream_cache_background_update(ngx_http_request_t *r,
    ngx_http_upstream_t *u)
{
    ngx_http_request_t  *sr;

    if (!r->cached || !r->cache->background) {
        return NGX_OK;
    }

    if (r == r->main) {
        r->preserve_body = 1;
    }

    if (ngx_http_subrequest(r, &r->uri, &r->args, &sr, NULL,
                            NGX_HTTP_SUBREQUEST_CLONE
                            |NGX_HTTP_SUBREQUEST_BACKGROUND)
        != NGX_OK)
    {
        return NGX_ERROR;
    }

    sr->header_only = 1;

    return NGX_OK;
}