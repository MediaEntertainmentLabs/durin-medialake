using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Configuration;
using System.IO;
using Azure.Storage;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using System.Net.Http;
using System.Text.Json;
using System.Diagnostics;

namespace VendorClientApp
{
    public enum VendorOperation
    {
        Upload,
        Download
    };


    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private async void Form1_Load(object sender, EventArgs e)
        {
            try
            {
                ListFilesInUploadFolder();
                ListFilePathsInBlobContainer();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }

        private void ListFilesInUploadFolder()
        {
            lbUpload.Items.Clear();
            string folderPath = (string)(ConfigurationManager.AppSettings["UploadFilesLocation"]);

            string[] filePaths = Directory.GetFiles(folderPath);
            string fileName = null;
            for (int i = 0; i < filePaths.Length; i++)
            {
                fileName = Path.GetFileName(filePaths[i]);
                lbUpload.Items.Add(fileName);
            }
        }

        private async void ListFilePathsInBlobContainer()
        {
            //cbDownload.Items.Clear();
            //cbUpload.Items.Clear();
            //lbDownload.Items.Clear();

            string containerName = (string)(ConfigurationManager.AppSettings["vendorContainerName"]);

            string connStr = (string)(ConfigurationManager.AppSettings["dnldSASConnectionString"]);

            BlobServiceClient blobServiceClient = new BlobServiceClient(connStr);

            BlobContainerClient blobContainerClient = blobServiceClient.GetBlobContainerClient(containerName);

            await foreach (BlobItem blobItem in blobContainerClient.GetBlobsAsync())
            {
                string asset = string.Empty;
                string pathBegin = string.Empty;
                string name = string.Empty;
                
                if (blobItem.Name.EndsWith(".mp4") || blobItem.Name.EndsWith(".mov"))
                {
                    string[] pathsec = blobItem.Name.Split('/');
                    asset = pathsec[3];
                    name = blobItem.Name.Substring(blobItem.Name.IndexOf($"/{asset}/") + asset.Length + 2);
                    pathBegin = blobItem.Name.Replace(name, "");

                    bool isPathExists = false;
                    foreach (var path in cbDownload.Items)
                    {
                        if (path.Equals(pathBegin))
                            isPathExists = true;
                    }
                    if (isPathExists == false)
                    {
                        cbDownload.Items.Add(pathBegin);
                        cbUpload.Items.Add(pathBegin);
                    }
                }
            }
        }

        private async void ListFilesInBlobContainer()
        {
            lbDownload.Items.Clear();

            string containerName = (string)(ConfigurationManager.AppSettings["vendorContainerName"]);
            
            string connStr = (string)(ConfigurationManager.AppSettings["dnldSASConnectionString"]);

            BlobServiceClient blobServiceClient = new BlobServiceClient(connStr);

            BlobContainerClient blobContainerClient = blobServiceClient.GetBlobContainerClient(containerName);
                        
            if (cbDownload.SelectedItem != null)
            {
                await foreach (BlobItem blobItem in blobContainerClient.GetBlobsAsync())
                {
                    string show = string.Empty;
                    string season = string.Empty;
                    string episode = string.Empty;
                    string asset = string.Empty;
                    string pathBegin = string.Empty;
                    string name = string.Empty;

                    if (blobItem.Name.EndsWith(".mp4") || blobItem.Name.EndsWith(".mov"))
                    {
                        string[] pathsec = blobItem.Name.Split('/');
                        show = pathsec[0];
                        season = pathsec[1];
                        episode = pathsec[2];
                        asset = pathsec[3];
                        name = blobItem.Name.Substring(blobItem.Name.IndexOf($"/{asset}/") + asset.Length + 2);
                        pathBegin = blobItem.Name.Replace(name, "");

                        string selectedPath = (string)cbDownload.SelectedItem;
                        if (selectedPath.Equals(pathBegin))
                        {
                            lbDownload.Items.Add(name);
                            //lbDownload.Items.Add(blobItem.Name);
                        }
                    }
                }
            }
        }

        private System.Diagnostics.Process ExecuteCommand(string commandText)
        {
            // https://docs.microsoft.com/en-us/troubleshoot/dotnet/csharp/wait-shelled-app-finish
            string strCmdText;
            strCmdText = "/C " + commandText;
            System.Diagnostics.Process azcpyProc = System.Diagnostics.Process.Start("CMD.exe", strCmdText);
            return azcpyProc;
        }

        private void btnUpload_Click(object sender, EventArgs e)
        {
            string azCopyCommandTemplate = "@@azCopyCommandFolder/azcopy.exe copy \"@@localPath\" \"@@storageURL\" --recursive=true\"";
            string azCopyCommandFolder = (string)(ConfigurationManager.AppSettings["AzCopyCommandFolder"]);
            string accountName = (string)(ConfigurationManager.AppSettings["upldStorageAccountName"]);
            string containerName = (string)(ConfigurationManager.AppSettings["vendorContainerName"]);
            string sas = (string)(ConfigurationManager.AppSettings["upldSAS"]);

            if(cbUpload.SelectedItem != null)
            {
                // Wait for the azcopy commands to complete
                var azcpyProcesses = new List<Process>();
                Process azcpyProc = null;

                //string sas = this.upldSAS;
                string storageURL = "https://" + accountName +".blob.core.windows.net/" + containerName + "/" + (string)cbUpload.SelectedItem + "?" + sas;
                string localPath = null;
                string azCopyCommand = null;
                string fileName = null;

                //StorageSASTokenURL
                for (int i = 0; i < lbUpload.CheckedItems.Count; i++)
                {
                    fileName = (string)(lbUpload.CheckedItems[i]);
                    localPath = GetPathForChoosenFile(fileName, VendorOperation.Upload);

                    azCopyCommand = 
                    azCopyCommandTemplate.Replace("@@azCopyCommandFolder", azCopyCommandFolder).Replace("@@localPath", localPath).Replace("@@storageURL", storageURL);

                    azcpyProc = ExecuteCommand(azCopyCommand);
                    azcpyProcesses.Add(azcpyProc);
                }

                foreach (var process in azcpyProcesses)
                {
                    try
                    {
                        process.WaitForExit();
                        process.Close();
                    }
                    catch { }
                }

                this.SendMailOnUpload();
            }
        }

        private async void SendMailOnUpload()
        {
            string sendMailLAUrl = (string)(ConfigurationManager.AppSettings["SendMail_LogicApp_URL"]);
            string vendorName = (string)(ConfigurationManager.AppSettings["vendorContainerName"]);
            string recipient = (string)(ConfigurationManager.AppSettings["Recipient"]);
            string subject = (string)(ConfigurationManager.AppSettings["UpldSubject"]) + vendorName;
            string emailBody = string.Empty;

            List<string> fileNameList = new List<string>();
            string fileName = string.Empty;

            for (int i = 0; i < lbUpload.CheckedItems.Count; i++)
            {
                fileName = (string)cbUpload.SelectedItem + (string)(lbUpload.CheckedItems[i]);
                fileNameList.Add(fileName);
            }

            if (fileNameList.Count > 0)
            {                
                emailBody = $" <br> List of Files uploaded successfully : <br> {string.Join("<br>", fileNameList.ToArray())} ";
                // requires using System.Net.Http;
                var client = new HttpClient();
                // requires using System.Text.Json;
                var jsonData = JsonSerializer.Serialize(new
                {
                    EmailBody = emailBody,
                    Recipient = recipient,
                    Subject = subject
                });

                HttpResponseMessage result = await client.PostAsync(
                    sendMailLAUrl,
                    new StringContent(jsonData, Encoding.UTF8, "application/json"));

                var statusCode = result.StatusCode.ToString();
            }
        }

        private void btnDownload_Click(object sender, EventArgs e)
        {
            string azCopyCommandTemplate = "@@azCopyCommandFolder/azcopy.exe copy \"@@storageURL\" \"@@localPath\" --recursive=true\"";
            string azCopyCommandFolder = (string)(ConfigurationManager.AppSettings["AzCopyCommandFolder"]);
            string accountName = (string)(ConfigurationManager.AppSettings["dnldStorageAccountName"]);
            string containerName = (string)(ConfigurationManager.AppSettings["vendorContainerName"]);
            string sas = (string)(ConfigurationManager.AppSettings["dnldSAS"]);
            //string sas = this.dnldSAS;
            string storageURL = "https://" + accountName + ".blob.core.windows.net/@@containerName/@@blobName?" + sas;
            string downloadFolder = (string)(ConfigurationManager.AppSettings["DownloadFilesLocation"]);
            string azCopyCommand = null;
            string cmdResult = null;
            string blobName = null;

            List<string> assetFileNameList = new List<string>();

            // Wait for the azcopy commands to complete
            var azcpyProcesses = new List<Process>();
            Process azcpyProc = null;

            //StorageSASTokenURL
            for (int i = 0; i < lbDownload.CheckedItems.Count; i++)
            {
                blobName = string.Concat((string)cbDownload.SelectedItem, (string)(lbDownload.CheckedItems[i]));

                string assetName = ((string)cbDownload.SelectedItem).Split('/')[3];
                bool canDownload = this.VendorAssetFileCanDownload(blobName, (string)(lbDownload.CheckedItems[i]), assetName, containerName);
                if (canDownload == true)
                {
                    azCopyCommand =
                    azCopyCommandTemplate.Replace("@@azCopyCommandFolder", azCopyCommandFolder)
                    .Replace("@@localPath", downloadFolder).Replace("@@storageURL", storageURL)
                    .Replace("@@containerName", containerName)
                    .Replace("@@blobName", blobName);

                    azcpyProc = ExecuteCommand(azCopyCommand);
                    azcpyProcesses.Add(azcpyProc);
                    this.SetVendorAssetDownloadCount(blobName, containerName);

                    //add to asset name list, to email on download completion
                    assetFileNameList.Add(blobName);
                }
                else
                {
                    MessageBox.Show($"File is already downloaded. Kindly reach out to Admin for further assistance. \n{blobName}");
                }
            }

            if(assetFileNameList.Count > 0)
            {
                foreach (var process in azcpyProcesses)
                {
                    try
                    {
                        process.WaitForExit();
                        process.Close();
                    }
                    catch { }
                }

                this.SendMailOnDownload(assetFileNameList);
            }
        }

        private void SetVendorAssetDownloadCount(string blobPath, string vendorContainer)
        {
            string[] paramList = blobPath.Split('/');
            string showContainer = paramList[0];
            string seasonName = paramList[1];
            string episodeName = paramList[2];
            string assetName = paramList[3];
            int indx = showContainer.Length + seasonName.Length + episodeName.Length + assetName.Length + 4;
            string assetFileName = blobPath.Substring(indx);

            string setVendorAssetDownloadCountUrl = (string)(ConfigurationManager.AppSettings["SetVendorAssetDownloadCount_URL"]);

            // requires using System.Net.Http;
            var client = new HttpClient();
            // requires using System.Text.Json;
            var jsonData = JsonSerializer.Serialize(new
            {
                assetBlobPath = blobPath,
                assetFileName = assetFileName,
                assetName = assetName,
                episodeName = episodeName,
                seasonName = seasonName,
                showContainer = showContainer,
                vendorContainer = vendorContainer
            });

            Task<HttpResponseMessage> postTask = client.PostAsync(
                setVendorAssetDownloadCountUrl,
                new StringContent(jsonData, Encoding.UTF8, "application/json"));
            HttpResponseMessage result = postTask.Result;

            var statusCode = result.StatusCode.ToString();
        }

        private bool VendorAssetFileCanDownload(string blobPath, string assetFileName, string assetName, string vendorContainer)
        {
            bool canDownload = true;
            string vendorAssetDownloadCountUrl = (string)(ConfigurationManager.AppSettings["GetVendorAssetDownloadCount_URL"]);
            int vendorAssetMaxDownloadCount = int.Parse((string)(ConfigurationManager.AppSettings["VendorAssetMaxDownloadCount"]));

            // requires using System.Net.Http;
            var client = new HttpClient();
            // requires using System.Text.Json;
            var jsonData = JsonSerializer.Serialize(new
            {
                assetBlobPath = blobPath,
                assetFileName = assetFileName,
                assetName = assetName,
                vendorContainer = vendorContainer
            });

            Task< HttpResponseMessage> postTask = client.PostAsync(
                vendorAssetDownloadCountUrl,
                new StringContent(jsonData, Encoding.UTF8, "application/json"));
            HttpResponseMessage result = postTask.Result;

            var statusCode = result.StatusCode.ToString();
            var body = result.Content.ReadAsStringAsync().Result;
            DownloadCount dc = JsonSerializer.Deserialize<DownloadCount>(body);
            canDownload = (int.Parse(dc.Count) < vendorAssetMaxDownloadCount) ? true : false;
            return canDownload;
        }

        private async void SendMailOnDownload(List<string> fileNameList)
        {
            string sendMailLAUrl = (string)(ConfigurationManager.AppSettings["SendMail_LogicApp_URL"]);
            string vendorName = (string)(ConfigurationManager.AppSettings["vendorContainerName"]);
            string recipient = (string)(ConfigurationManager.AppSettings["Recipient"]);
            string subject = (string)(ConfigurationManager.AppSettings["DnldSubject"]) + vendorName;
            string emailBody = string.Empty;

            emailBody = $" <br> List of Files downloaded successfully : <br> {string.Join("<br>", fileNameList.ToArray())} ";
            // requires using System.Net.Http;
            var client = new HttpClient();
            // requires using System.Text.Json;
            var jsonData = JsonSerializer.Serialize(new
            {
                EmailBody = emailBody,
                Recipient = recipient,
                Subject = subject
            });

            HttpResponseMessage result = await client.PostAsync(
                sendMailLAUrl,
                new StringContent(jsonData, Encoding.UTF8, "application/json"));

            var statusCode = result.StatusCode.ToString();
        }

        private void btnPlay_Click(object sender, EventArgs e)
        {
            if (lbUpload.SelectedItem != null)
            {
                string fileName = lbUpload.SelectedItem.ToString();
                string filePath = GetPathForChoosenFile(fileName, VendorOperation.Upload);
                PlayMediaFile(filePath);
            }
        }

        string GetPathForChoosenFile(string fileName, VendorOperation vendorOperation)
        {
            string folderPath = (vendorOperation == VendorOperation.Download) ?
                (string)(ConfigurationManager.AppSettings["DownloadFilesLocation"]) :
                (string)(ConfigurationManager.AppSettings["UploadFilesLocation"]);

            string filePath = Path.Combine(folderPath, fileName);
            return filePath;
        }

        void PlayMediaFile(string path)
        {
            ctrlWMP.URL = path;
            ctrlWMP.settings.autoStart = true;
        }

        private void btnRefreshLocalFilesList_Click(object sender, EventArgs e)
        {
            ListFilesInUploadFolder();
        }

        private void btnRefreshBlobFilesList_Click(object sender, EventArgs e)
        {
            ListFilePathsInBlobContainer();
            ListFilesInBlobContainer();
        }

        private void Play_Click(object sender, EventArgs e)
        {
            if (lbDownload.SelectedItem != null)
            {
                string fileName = lbDownload.SelectedItem.ToString();
                string[] pathsec = fileName.Split('/');
                if (pathsec.Length > 0)
                    fileName = pathsec[pathsec.Length - 1];

                string filePath = GetPathForChoosenFile(fileName, VendorOperation.Download);
                PlayMediaFile(filePath);
            }
        }

        private void cbDownload_SelectedIndexChanged(object sender, EventArgs e)
        {
            ListFilesInBlobContainer();
        }

        //private void ctrlWMP_Enter(object sender, EventArgs e)
        //{

        //}
    }
}
