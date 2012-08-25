#include "FindJpeg.hh"
#include <cstdio>
#include <cstring>

bool FindJpeg::scan () 
{
  struct dirent entry;
  struct dirent *de;
  while (readdir_r(dh_,&entry,&de) == 0) 
    {
      if (de == 0)
	break;
      
      if (de->d_name[0] == '.')
	continue;
      switch (de->d_type) 
	{
	case DT_DIR:
	  dirs_.push_back( dir_ + "/" + de->d_name );
	  break;
	case DT_REG:
	  int len = strlen(de->d_name);
	  if (len < 5) break;
	  const char * ext = de->d_name + len - 4;
	  if (strncasecmp(ext,".jpg",4)) break;
	  file_ = dir_ + "/" + de->d_name;
	  return true;
	}
    }
  return false;
}

bool FindJpeg::next () 
{
  if (dh_) 
    {
      if ( scan() )
	return true;
      else
	{
	  closedir( dh_ );
	  dh_ = 0;
	}
      
    }
  while( dirs_.size() ) 
    {
      dir_ = dirs_.back();
      dirs_.pop_back();
      dh_ = opendir(dir_.c_str());
      if (dh_ == NULL)
	{
	  perror(dir_.c_str());
	}
      else
	{
	  if ( scan() ) return true;
	}
    }
  return false;
  
}

      
