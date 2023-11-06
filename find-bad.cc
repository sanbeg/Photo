#include <cstdio>
#include "FindJpeg.hh"
#include "ValidJpeg.hh"

int main (int ac, const char ** argv ) 
{
  if (ac < 2) 
    {
      fprintf (stderr, "Usage: %s DIR ...\n", *argv);
      return 1;
    }
  
  for (int i=1; i<ac; ++i) 
    {
      
      FindJpeg fj(argv[i]);
      ValidJpeg vj;
      while (fj.next()) 
	{
	  const char * file = fj.get_c();
	  //fprintf(stderr, "got file: %s\n", file);
	  
	  
	  if (file == 0) 
	    {
	      fprintf(stderr, "null file return\n");
	      continue;
	    }
	  else if (file[0] == 0) 
	    {
	      fprintf(stderr, "empty file name return\n");
	      continue;
	    }
	  else if (not vj.open(file) ) 
	    {
	      perror(file);
	      continue;
	    }
      
	  int status = vj.valid_jpeg();
	  //int status = vj.short_jpeg();
	  if (status != 0)
	    puts(file);
	}
    }
}

