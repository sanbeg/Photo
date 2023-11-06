#include <string>
#include <vector>
#include <sys/types.h>
#include <dirent.h>

class FindJpeg 
{
private:
  std::vector<std::string> dirs_;
  DIR * dh_;
  std::string file_;
  std::string dir_;
  
  bool scan();
  
public:
  FindJpeg( std::string const & dir ) 
  {
    dh_ = 0;
    dirs_.push_back(dir);
  }
  ~FindJpeg() 
  {
    if (dh_) closedir(dh_);
  }

  bool next();

  std::string get() const
  {
    fprintf(stderr, "getting %s\n", file_.c_str());
    
    return file_;
  }
  
  const char * get_c() const 
  {
    return file_.c_str();
  }
  
  
};

  
  
