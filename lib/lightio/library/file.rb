module LightIO::Library
  class File < LightIO::Library::IO
    include Base
    include LightIO::Wrap::IOWrapper

    mock ::File
    extend LightIO::Module::File::ClassMethods
  end
end
