#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mcx_utils.h"

void mcx_savedata(float *dat,int len,char *name){
     FILE *fp;
     fp=fopen(name,"wb");
     fwrite(dat,sizeof(float),len,fp);
     fclose(fp);
}

void mcx_error(int id,char *msg){
     fprintf(stderr,"MCX ERROR(%d):%s\n",id,msg);
     exit(id);
}

void mcx_readconfig(char *fname, Config *cfg){
     if(fname[0]==0)
     	mcx_loadconfig(stdin,cfg);
     else{
     	FILE *fp=fopen(fname,"rt");
	if(fp==NULL) mcx_error(-2,"can not load specified config file");
	mcx_loadconfig(fp,cfg); 
	fclose(fp);   
     }
}

void mcx_writeconfig(char *fname, Config *cfg){
     if(fname[0]==0)
     	mcx_saveconfig(stdout,cfg);
     else{
     	FILE *fp=fopen(fname,"wt");
	if(fp==NULL) mcx_error(-2,"can not load specified config file");
	mcx_saveconfig(fp,cfg);     
	fclose(fp);
     }
}

void mcx_initcfg(Config *cfg){
     cfg->medianum=0;
     cfg->detnum=0;
     cfg->dim.x=0;
     cfg->dim.y=0;
     cfg->dim.z=0;

     cfg->prop=NULL;
     cfg->detpos=NULL;
     cfg->vol=NULL;
}

void mcx_clearcfg(Config *cfg){
     if(cfg->medianum)
     	free(cfg->prop);
     if(cfg->detnum)
     	free(cfg->detpos);
     if(cfg->dim.x && cfg->dim.y && cfg->dim.z)
        free(cfg->vol);

     mcx_initcfg(cfg);
}

void mcx_loadconfig(FILE *in, Config *cfg){
     int i;
     char filename[MAX_PATH_LENGTH]={0};
     
     if(in==stdin) fprintf(stdout,"Please specify the total number of photons: [1000000]\n\t");
     fscanf(in,"%d", &(cfg->nphoton) ); 
     if(in==stdin) fprintf(stdout,"Please specify random number generator seed: [1234567]\n\t");
     fscanf(in,"%d", &(cfg->seed) );
     if(in==stdin) fprintf(stdout,"Please specify the position of the source: [10 10 5]\n\t");
     fscanf(in,"%f %f %f", &(cfg->srcpos.x),&(cfg->srcpos.y),&(cfg->srcpos.z) );
     if(in==stdin) fprintf(stdout,"Please specify the normal direction of the source fiber: [0 0 1]\n\t");
     fscanf(in,"%f %f %f", &(cfg->srcdir.x),&(cfg->srcdir.y),&(cfg->srcdir.z) );
     if(in==stdin) fprintf(stdout,"Please specify the time gates in seconds (start end and step) [0.0 1e-9 1e-10]\n\t");
     fscanf(in,"%f %f %f", &(cfg->tstart),&(cfg->tend),&(cfg->tstep) );

     if(in==stdin) fprintf(stdout,"Please specify the path to the volume binary file:\n\t");
     fscanf(in,"%s", filename);
     
     if(in==stdin) fprintf(stdout,"Please specify the x voxel size (in mm), x dimension, min and max x-index [1.0 100 0 100]:\n\t");
     fscanf(in,"%f %d %d %d", &(cfg->steps.x),&(cfg->dim.x),&(cfg->crop0.x),&(cfg->crop1.x));
     if(in==stdin) fprintf(stdout,"Please specify the y voxel size (in mm), y dimension, min and max y-index [1.0 100 0 100]:\n\t");
     fscanf(in,"%f %d %d %d", &(cfg->steps.y),&(cfg->dim.y),&(cfg->crop0.y),&(cfg->crop1.y));
     if(in==stdin) fprintf(stdout,"Please specify the z voxel size (in mm), z dimension, min and max z-index [1.0 100 0 100]:\n\t");
     fscanf(in,"%f %d %d %d", &(cfg->steps.z),&(cfg->dim.z),&(cfg->crop0.z),&(cfg->crop1.z));
     if(in==stdin) fprintf(stdout,"Please specify the total types of media:\n\t");
     fscanf(in,"%d", &(cfg->medianum));
     cfg->prop=(Medium*)malloc(sizeof(Medium)*cfg->medianum);
     for(i=0;i<cfg->medianum;i++){
        if(in==stdin) fprintf(stdout,"Please define medium #%d: mus(1/mm), anisotropy, mua(1/mm) and refraction index: [1.01 0.01 0.04 1.37]\n\t",i);
     	fscanf(in, "%f %f %f %f", &(cfg->prop[i].mus),&(cfg->prop[i].g),&(cfg->prop[i].mua),&(cfg->prop[i].n));
     }
     if(in==stdin) fprintf(stdout,"Please specify the total number of detectors:\n\t");
     fscanf(in,"%d", &(cfg->detnum));
     cfg->prop=(Medium*)malloc(sizeof(Medium)*cfg->detnum);
     for(i=0;i<cfg->detnum;i++){
        if(in==stdin) fprintf(stdout,"Please define detector #%d: x,y,z (in mm) and fiber diameters (in mm): [5 5 5 1]\n\t",i);
     	fscanf(in, "%f %f %f %f", &(cfg->detpos[i].x),&(cfg->detpos[i].y),&(cfg->detpos[i].z),&(cfg->detpos[i].w));
     }
     if(filename[0]){
        mcx_loadvolume(filename,cfg);
     }else{
     	mcx_error(-4,"one must specify a binary volume file in order to run the simulation");
     }
}

void mcx_loadvolume(char *filename,Config *cfg){
     int datalen,res;
     FILE *fp=fopen(filename,"rb");
     if(fp==NULL){
     	     mcx_error(-5,"specified binary volume file does not exist");
     }
     if(cfg->vol){
     	     free(cfg->vol);
     	     cfg->vol=NULL;
     }
     datalen=cfg->dim.x*cfg->dim.y*cfg->dim.z;
     cfg->vol=(unsigned char*)malloc(sizeof(unsigned char)*datalen);
     res=fread(cfg->vol,sizeof(unsigned char),datalen,fp);
     fclose(fp);
     if(res!=datalen){
     	 mcx_error(-6,"file size does not match specified dimensions");
     }
}
void mcx_saveconfig(FILE *out, Config *cfg){
     int i;

     fprintf(out,"%d\n", (cfg->nphoton) ); 
     fprintf(out,"%d\n", (cfg->seed) );
     fprintf(out,"%f %f %f\n", (cfg->srcpos.x),(cfg->srcpos.y),(cfg->srcpos.z) );
     fprintf(out,"%f %f %f\n", (cfg->srcdir.x),(cfg->srcdir.y),(cfg->srcdir.z) );
     fprintf(out,"%f %f %f\n", (cfg->tstart),(cfg->tend),(cfg->tstep) );
     fprintf(out,"%f %d %d %d\n", (cfg->steps.x),(cfg->dim.x),(cfg->crop0.x),(cfg->crop1.x));
     fprintf(out,"%f %d %d %d\n", (cfg->steps.y),(cfg->dim.y),(cfg->crop0.y),(cfg->crop1.y));
     fprintf(out,"%f %d %d %d\n", (cfg->steps.z),(cfg->dim.z),(cfg->crop0.z),(cfg->crop1.z));
     fprintf(out,"%d", (cfg->medianum));
     for(i=0;i<cfg->medianum;i++){
     	fprintf(out, "%f %f %f %f\n", (cfg->prop[i].mus),(cfg->prop[i].g),(cfg->prop[i].mua),(cfg->prop[i].n));
     }
     fprintf(out,"%d", (cfg->detnum));
     for(i=0;i<cfg->detnum;i++){
     	fprintf(out, "%f %f %f %f\n", (cfg->detpos[i].x),(cfg->detpos[i].y),(cfg->detpos[i].z),(cfg->detpos[i].w));
     }
}

void mcx_parsecmd(int argc, char* argv[], Config *cfg){
     int i=1,isinteractive=1;
     char filename[MAX_PATH_LENGTH]={0};
     
     if(argc<=1){
     	mcx_usage();
     	exit(0);
     }
     while(i<argc){
     	    if(argv[i][0]=='-'){
	        switch(argv[i][1]){
		     case 'i':
		     		isinteractive=1;
				break;
		     case 'f': 
		     		isinteractive=0;
		     	        if(i<argc-1)
				    strcpy(filename,argv[++i]);
				else
				    mcx_error(-1,"incomplete input");
				break;
		     case 'm':
		     	        if(i<argc-1)
		     		    cfg->totalmove=atoi(argv[++i]);
				else
				    mcx_error(-1,"incomplete input");
		     	        break;
		     case 't':
		     	        if(i<argc-1)
		     		    cfg->nthread=atoi(argv[++i]);
				else
				    mcx_error(-1,"incomplete input");
		     	        break;
		     case 's':
		     	        if(i<argc-1)
		     		    strcpy(cfg->session,argv[++i]);
				else
				    mcx_error(-1,"incomplete input");
		     	        break;
		}
	    }
	    i++;
     }
     if(isinteractive){
          mcx_readconfig("",cfg);
     }else{
     	  mcx_readconfig(filename,cfg);
     }
}

void mcx_usage(){
     printf("\
#######################################################################################\n\
#                     Monte-Carlo Extreme (MCX) -- CUDA                               #\n\
#             Author: Qianqian Fang <fangq at nmr.mgh.harvard.edu>                    #\n\
#######################################################################################\n\
usage: mcextreme <options>\n\
where possible options include\n\
     -i 	   interactive mode\n\
     -f config     read config from a file\n\
     -m n_move	   total move per thread\n\
     -t n_thread   total thread number\n\
     -s sessionid  a string to identify this specific simulation\n");
}