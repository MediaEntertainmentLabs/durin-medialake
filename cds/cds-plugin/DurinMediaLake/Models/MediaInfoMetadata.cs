namespace Microsoft.Media.DurinMediaLake.Models
{
    using Newtonsoft.Json;
    using System.Collections.Generic;
    public class MediaInfoMetadata
    {
        public Media media { get; set; }
    }

    public class Media
    {
        public string @ref { get; set; }
        public Track[] track { get; set; }
    }

    public class Track
    {
        public string TrackType { get; set; }
        public string Format { get; set; }

        [JsonExtensionData]
        public Dictionary<string, object> ExtensionData { get; set; }
    }
}
