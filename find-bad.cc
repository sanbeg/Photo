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
	  const char * file = fj.get().c_str();
       
	  if (not vj.open(file) ) 
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

