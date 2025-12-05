create or replace api integration kipistone_mh_git_int
    api_provider = git_https_api
    api_allowed_prefixes = ('https://github.com/adpatil-kipi/Kipi_Stone_MH.git')
    enabled = true
    allowed_authentication_secrets = all
    -- api_user_authentication = (type = snowflake_github_app ) -- enable OAuth support
    comment='Git integration for Kipi Stone project';