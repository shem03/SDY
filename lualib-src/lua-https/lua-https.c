
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <curl/curl.h>

#include "lua.h"
#include "lauxlib.h"

#define SKIP_PEER_VERIFICATION
static int query_id = 0;
struct curl_data
{
    lua_State *L;
    int lua_index;
};

static size_t write_data(void *ptr, size_t size, size_t nmemb, void *stream)  
{
    struct curl_data *data = (struct curl_data *)stream;
    // printf("write_data: %s  size:%d nmemb:%d lua_index:%d\n", ptr, size, nmemb, data->lua_index);
    lua_rawgetp(data->L, LUA_REGISTRYINDEX, &data->lua_index);
    
    lua_pushlstring(data->L, (char*) ptr, nmemb * size);
    lua_call(data->L, 1, 0);
    free(data);
    return nmemb*size;
}

static int query(struct curl_data *data, const char * query_url, const char * query_data)
{
    CURL *curl;
    CURLcode res = CURLE_OK;
    // printf("query:%s\n", query_url);
    curl = curl_easy_init();
    if(curl) {
        curl_easy_setopt(curl, CURLOPT_URL, query_url);

#ifdef SKIP_PEER_VERIFICATION
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, 0L);
#endif
#ifdef SKIP_HOSTNAME_VERIFICATION
        curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST, 0L);
#endif
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, data);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data);
        if (query_data)
        {
            curl_easy_setopt(curl,CURLOPT_POST,1); //设置问非0表示本次操作为post
            curl_easy_setopt(curl,CURLOPT_POSTFIELDS,query_data); //post参数  
        }
    
        res = curl_easy_perform(curl);

        curl_easy_cleanup(curl);
    }

    return (int)res;
}

static struct curl_data * setnotify(lua_State *L)
{
    struct curl_data * data = malloc(sizeof(struct curl_data));
    lua_settop(L, 1);
    data->lua_index = query_id++;
    lua_rawsetp(L, LUA_REGISTRYINDEX, &data->lua_index);

    lua_rawgeti(L, LUA_REGISTRYINDEX, LUA_RIDX_MAINTHREAD);
    lua_State *gL = lua_tothread(L,-1);
    data->L = gL;

    return data;
}

static int _get(lua_State *L) {
    size_t len;
    luaL_checktype(L, 1, LUA_TFUNCTION);
    const char * query_url = luaL_checklstring(L, 2, &len);
    struct curl_data * data = setnotify(L);
    int res = query(data, query_url, NULL);
    lua_pushnumber(L, res);
    if (res != CURLE_OK) {
        free(data);
        lua_pushstring(L, curl_easy_strerror(res));
        return 2;
    }
    return 1;
}

static int _post(lua_State *L) {
    size_t len, data_len;
    luaL_checktype(L,1,LUA_TFUNCTION);
    const char * query_url = luaL_checklstring(L, 2, &len);
    const char * query_data = luaL_checklstring(L, 3, &data_len);
    struct curl_data * data = setnotify(L);
    int res = query(data, query_url, query_data);
    lua_pushnumber(L, res);
    if (res != CURLE_OK) {
        free(data);
        lua_pushstring(L, curl_easy_strerror(res));
        return 2;
    }
    return 1;
}

static int
_release(lua_State *L) {
    curl_global_cleanup();
    return 0;
}

int luaopen_https(lua_State *L) {
    luaL_checkversion(L);

    luaL_Reg l[] = {
        {"get", _get},
        {"post", _post},

        {NULL, NULL}
    };

    luaL_newlib(L, l);

    curl_global_init(CURL_GLOBAL_DEFAULT);

    lua_createtable(L, 0, 2);
    lua_setfield(L, -2, "__index");
    lua_pushcfunction(L, _release);
    lua_setfield(L, -2, "__gc");

    return 1;
}
