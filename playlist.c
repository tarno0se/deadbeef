#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <fnmatch.h>
#include "playlist.h"
#include "codec.h"
#include "cwav.h"
#include "cvorbis.h"
#include "cmod.h"

playItem_t *playlist_head;
playItem_t *playlist_tail;
playItem_t *playlist_current;

int
ps_add_file (const char *fname) {
    if (!fname) {
        return -1;
    }
    playItem_t *it = malloc (sizeof (playItem_t));
    memset (it, 0, sizeof (playItem_t));
    // detect codec
    const char *eol = fname + strlen (fname) - 1;
    while (*eol != '.') {
        eol--;
        }
    eol++;
    if (!strcasecmp (eol, "ogg")) {
        it->codec = &cvorbis;
    }
    else if (!strcasecmp (eol, "wav")) {
        it->codec = &cwav;
    }
    else if (!strcasecmp (eol, "mod")) {
        it->codec = &cmod;
    }
    // copy string
    it->fname = strdup (fname);
    it->displayname = strdup (fname);
    it->timestart = -1;
    it->timeend = -1;

    if (!playlist_tail) {
        playlist_tail = playlist_head = it;
    }
    else {
        playlist_tail->next = it;
        it->prev = playlist_tail;
        playlist_tail = it;
    }
}

int
ps_add_dir (const char *dirname) {
    struct dirent **namelist = NULL;
    int n;

    n = scandir (dirname, &namelist, NULL, NULL);
    if (n < 0)
    {
        if (namelist)
            free (namelist);
        return -1;	// not a dir or no read access
    }
    else
    {
        while (n--)
        {
            // no hidden files
            if (namelist[n]->d_name[0] != '.')
            {
                ps_add_file (namelist[n]->d_name);
            }
            free (namelist[n]);
        }
        free (namelist);
    }
    return 0;
}

int
ps_remove (playItem_t *it) {
    if (!it)
        return -1;
    if (it->fname) {
        free (it->fname);
    }
    if (it->displayname) {
        free (it->displayname);
    }
    if (it->prev) {
        it->prev->next = it->next;
    }
    else {
        playlist_head = it->next;
    }
    if (it->next) {
        it->next->prev = it->prev;
    }
    else {
        playlist_tail = it->prev;
    }
    free (it);
    return 0;
}

