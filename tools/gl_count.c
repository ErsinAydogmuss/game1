/*
 * Ekran kartı nesnelerinin sayacı (yalnızca Linux masaüstünde, geliştirme için; oyunun paketine girmez; Kazı'dan).
 * Godot'nun OpenGL nesnelerini (tampon, doku, çerçeve, VAO, program, fence) ve glBufferData çağrılarını sayar: Godot
 * GL işlevlerini dlsym / glXGetProcAddressARB ile bulur, bu kitaplık ikisini de sarar. 15 sn'de bir ve çıkışta
 * "GLSAY ... buffers=<canlı>(+<kurulan>) ..." satırı yazar. Oynarken canlı sayılar sabit kalmalı, kurulanlar az artmalı
 * (Kazı 0.14.3: her karede yeni ağ kuran şeyler telefonun ekran kartı sürücüsünü belleksiz bırakıp oyunu kapatıyordu).
 *
 * GLSAY_EVERY=1 ile her saniye (perf senaryosunun "PERF_SAAT" satırlarıyla eşlenir: tools/gl_windows.py).
 *
 *   gcc -O2 -shared -fPIC -o "$SCRATCH/gl_count.so" tools/gl_count.c -ldl -lpthread
 *   LD_PRELOAD="$SCRATCH/gl_count.so" xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
 *     --audio-driver Dummy --resolution 1280x720 -- --autoplay --scenario=perf --part=soak --seconds=300 2> gl.log
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <stdatomic.h>
#include <time.h>
#include <stdlib.h>

typedef unsigned int GLuint; typedef int GLsizei; typedef unsigned int GLenum; typedef long GLsizeiptr; typedef void* GLsync;
typedef void (*fp_gen)(GLsizei, GLuint*); typedef void (*fp_del)(GLsizei, const GLuint*);
typedef GLuint (*fp_create)(void); typedef GLuint (*fp_create_t)(GLenum); typedef void (*fp_delone)(GLuint);
typedef GLsync (*fp_fence)(GLenum, unsigned int); typedef void (*fp_delsync)(GLsync);
typedef void (*fp_bufdata)(GLenum, GLsizeiptr, const void*, GLenum);
typedef void* (*fp_proc)(const char*);

enum { BUF, TEX, FBO, RBO, VAO, PROG, SHADER, SYNC, N };
static const char *names[N] = {"buffers","textures","framebuffers","renderbuffers","vaos","programs","shaders","syncs"};
static atomic_long gen[N], del[N], bufdata_calls, bufdata_bytes;
static fp_gen r_gen[N]; static fp_del r_del[N];
static fp_create r_cprog; static fp_create_t r_cshader; static fp_delone r_dprog, r_dshader;
static fp_fence r_fence; static fp_delsync r_dsync; static fp_bufdata r_bufdata;
static fp_proc real_proc, real_proc_arb;

#define GENW(I) static void g##I(GLsizei n, GLuint *ids){ r_gen[I](n, ids); atomic_fetch_add(&gen[I], n);} \
	static void d##I(GLsizei n, const GLuint *ids){ long k=0; for(int i=0;i<n;i++) if(ids[i]) k++; atomic_fetch_add(&del[I], k); r_del[I](n, ids);}
GENW(0) GENW(1) GENW(2) GENW(3) GENW(4)
static GLuint cprog(void){ GLuint r=r_cprog(); if(r) atomic_fetch_add(&gen[PROG],1); return r; }
static void dprog(GLuint p){ if(p) atomic_fetch_add(&del[PROG],1); r_dprog(p); }
static GLuint cshader_t(GLenum t){ GLuint r=r_cshader(t); if(r) atomic_fetch_add(&gen[SHADER],1); return r; }
static void dshader(GLuint s){ if(s) atomic_fetch_add(&del[SHADER],1); r_dshader(s); }
static GLsync fence(GLenum c, unsigned int f){ GLsync s=r_fence(c,f); if(s) atomic_fetch_add(&gen[SYNC],1); return s; }
static void dsync(GLsync s){ if(s) atomic_fetch_add(&del[SYNC],1); r_dsync(s); }
static void bufdata(GLenum t, GLsizeiptr sz, const void *d, GLenum u){ atomic_fetch_add(&bufdata_calls,1); atomic_fetch_add(&bufdata_bytes, sz); r_bufdata(t,sz,d,u); }

static void *wrap(const char *name, void *p) {
	if (!p) return p;
	static const char *g[] = {"glGenBuffers","glGenTextures","glGenFramebuffers","glGenRenderbuffers","glGenVertexArrays"};
	static const char *d[] = {"glDeleteBuffers","glDeleteTextures","glDeleteFramebuffers","glDeleteRenderbuffers","glDeleteVertexArrays"};
	static void *gw[] = {(void*)g0,(void*)g1,(void*)g2,(void*)g3,(void*)g4};
	static void *dw[] = {(void*)d0,(void*)d1,(void*)d2,(void*)d3,(void*)d4};
	for (int i = 0; i < 5; i++) {
		if (!strcmp(name, g[i])) { r_gen[i] = (fp_gen)p; return gw[i]; }
		if (!strcmp(name, d[i])) { r_del[i] = (fp_del)p; return dw[i]; }
	}
	if (!strcmp(name, "glCreateProgram")) { r_cprog = (fp_create)p; return (void*)cprog; }
	if (!strcmp(name, "glDeleteProgram")) { r_dprog = (fp_delone)p; return (void*)dprog; }
	if (!strcmp(name, "glCreateShader")) { r_cshader = (fp_create_t)p; return (void*)cshader_t; }
	if (!strcmp(name, "glDeleteShader")) { r_dshader = (fp_delone)p; return (void*)dshader; }
	if (!strcmp(name, "glFenceSync")) { r_fence = (fp_fence)p; return (void*)fence; }
	if (!strcmp(name, "glDeleteSync")) { r_dsync = (fp_delsync)p; return (void*)dsync; }
	if (!strcmp(name, "glBufferData")) { r_bufdata = (fp_bufdata)p; return (void*)bufdata; }
	return p;
}
static void *my_proc(const char *n) { return wrap(n, real_proc(n)); }
static void *my_proc_arb(const char *n) { return wrap(n, real_proc_arb(n)); }

static void report(void) {
	fprintf(stderr, "GLSAY %ld", (long)time(NULL));
	for (int i = 0; i < N; i++) fprintf(stderr, " %s=%ld(+%ld)", names[i], gen[i] - del[i], (long)gen[i]);
	fprintf(stderr, " bufferdata=%ld/%ldMB\n", (long)bufdata_calls, (long)(bufdata_bytes >> 20));
}
__attribute__((destructor)) static void at_exit_report(void) { if (gen[BUF]) report(); }
static void *reporter(void *arg) {
	(void)arg;
	/* GLSAY_EVERY=1: her saniye (botun PERF_SAAT satırlarıyla bir anın kurduklarını ayırmak için). */
	const char *every = getenv("GLSAY_EVERY");
	int seconds = every && atoi(every) > 0 ? atoi(every) : 15;
	for (;;) {
		sleep(seconds);
		struct timespec now; clock_gettime(CLOCK_REALTIME, &now);
		fprintf(stderr, "GLSAY %.3f", now.tv_sec + now.tv_nsec / 1e9);
		for (int i = 0; i < N; i++) fprintf(stderr, " %s=%ld(+%ld)", names[i], gen[i] - del[i], (long)gen[i]);
		fprintf(stderr, " bufferdata=%ld/%ldMB\n", (long)bufdata_calls, (long)(bufdata_bytes >> 20));
	}
	return NULL;
}

static void *(*real_dlsym)(void *, const char *);
void *dlsym(void *h, const char *name) {
	if (!real_dlsym) {
		real_dlsym = dlvsym(RTLD_NEXT, "dlsym", "GLIBC_2.34");
		if (!real_dlsym) real_dlsym = dlvsym(RTLD_NEXT, "dlsym", "GLIBC_2.2.5");
	}
	void *p = real_dlsym(h, name);
	if (!p) return p;
	if (!strcmp(name, "glXGetProcAddressARB")) { real_proc_arb = (fp_proc)p; return (void*)my_proc_arb; }
	if (!strcmp(name, "glXGetProcAddress")) { real_proc = (fp_proc)p; return (void*)my_proc; }
	if (!strncmp(name, "gl", 2) && name[2] >= 'A' && name[2] <= 'Z') return wrap(name, p);
	return p;
}

__attribute__((constructor)) static void start(void) {
	pthread_t t; pthread_create(&t, NULL, reporter, NULL); pthread_detach(t);
}
