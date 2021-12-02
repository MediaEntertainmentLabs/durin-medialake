using System;
using System.Collections.Generic;
using System.Text;

namespace Func_ParseMediaMetadata
{
    public class MetadataSrc
    {
        public MediaSrc media { get; set; }
    }

    public class MediaSrc
    {
        public string _ref { get; set; }
        public object[] track { get; set; }
    }

}
