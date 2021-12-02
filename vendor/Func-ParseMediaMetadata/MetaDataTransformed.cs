using System;
using System.Collections.Generic;
using System.Text;

namespace Func_ParseMediaMetadata
{
    //class MetaDataTransformed
    //{
    //}


    public class MetadataTransformed
    {
        public Media[] media { get; set; }
    }

    public class Media
    {
        public string track { get; set; }
        public string format { get; set; }
        public Type[] type { get; set; }
    }

    public class Type
    {
        public string key { get; set; }
        public string value { get; set; }
    }

}
