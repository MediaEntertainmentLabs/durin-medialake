namespace Microsoft.Media.DurinMediaLake.Constant
{
    public class PluginConstants
    {
        public const string Target = "Target";
    }

    public class MediaAssetFileConstants
    {
        public const string EntityLogicalName = "media_assetfiles";
        public const string MediaInfoMetadata = "media_mediainfometadata";
        public const string UploadStatus = "media_uploadstatus";
        public const string AlefileContent = "media_alefilecontent";
        public const string BlobPath = "media_blobpath";
        public const string miscInfo = "media_miscinfo";
        public const string Status = "statecode";
    }

    public class UploadStatus
    {
        public const int Completed = 207940001;
        public const int Started = 207940000;
        public const int PartiallyUpload = 207940003;
    }

    public class MediaAssetConstants
    {
        public const string EntityLogicalName = "media_asset";
        public const string UploadedFileCount = "media_uploadedfilecount";
        public const string AssetStatus = "media_assetstatus";
        public const string UploadedFile = "media_uploadedfile";
        public const string FolderFileCount = "media_folderfilecount";
    }

    public class MediaTrackConstants
    {
        public const string EntityLogicalName = "media_track";
        public const string Type = "media_type";
        public const string Format = "media_format";
        public const string RefAssetFile = "media_assetfile";
    }

    public class MetadataConstants
    {
        public const string EntityLogicalName = "media_metadata";
        public const string KeyName = "media_name";
        public const string KeyValue = "media_keyvalue";
        public const string RefTrack = "media_track";
        public const string CameraMetadataEntityLogicalName = "media_camerarawfilemetadata";
    }

    public class MiscInfo
    {
        public string AleFileNameField { get; set; }
        public string MatchType { get; set; }
        public int TruncateCharFromStart { get; set; }
        public int TruncateCharFromEnd { get; set; }
    }

    public enum FileType
    {
        Audio = 207940000,
        Video = 207940001,
        Image = 207940002,
        Other = 207940003,
        Script = 207940004,
    };
}
