using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Configuration;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using System.Windows.Forms;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

namespace SecureMediaURLGenApp
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            try
            {
                ListFilePathsInBlobContainer();
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }

        private async void ListFilePathsInBlobContainer()
        {
            //cbPaths.Items.Clear();
            //clbFiles.Items.Clear();

            string containerName = string.Empty;

            string connStr = (string)(ConfigurationManager.AppSettings["prdhSASConnectionString"]);

            BlobServiceClient blobServiceClient = new BlobServiceClient(connStr);

            await foreach (BlobContainerItem blobContainerItem in blobServiceClient.GetBlobContainersAsync())
            {
                containerName = blobContainerItem.Name;

                BlobContainerClient blobContainerClient = blobServiceClient.GetBlobContainerClient(containerName);

                await foreach (BlobItem blobItem in blobContainerClient.GetBlobsAsync())
                {
                    string asset = string.Empty;
                    string pathBegin = string.Empty;
                    string name = string.Empty;

                    if (blobItem.Name.EndsWith(".mp4") || blobItem.Name.EndsWith(".mov"))
                    {
                        string[] pathsec = blobItem.Name.Split('/');
                        asset = pathsec[2];
                        name = blobItem.Name.Substring(blobItem.Name.IndexOf($"/{asset}/") + asset.Length + 2);
                        pathBegin = string.Concat(containerName, '/', blobItem.Name.Replace(name, ""));

                        bool isPathExists = false;
                        foreach (var path in cbPaths.Items)
                        {
                            if (path.Equals(pathBegin))
                                isPathExists = true;
                        }
                        if (isPathExists == false)
                        {
                            cbPaths.Items.Add(pathBegin);
                        }
                    }
                }
            }
        }

        private async void ListFilesInBlobContainer()
        {
            clbFiles.Items.Clear();
            textBoxURI.Clear();

            if (cbPaths.SelectedItem != null)
            {
                string selectedContainerName = ((string)cbPaths.SelectedItem).Split('/')[0];
                string containerName = string.Empty;

                string connStr = (string)(ConfigurationManager.AppSettings["prdhSASConnectionString"]);

                BlobServiceClient blobServiceClient = new BlobServiceClient(connStr);

                await foreach (BlobContainerItem blobContainerItem in blobServiceClient.GetBlobContainersAsync())
                {
                    containerName = blobContainerItem.Name;

                    if (!(selectedContainerName.Equals(containerName)))
                        continue;

                    BlobContainerClient blobContainerClient = blobServiceClient.GetBlobContainerClient(containerName);

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
                            show = containerName;
                            season = pathsec[0];
                            episode = pathsec[1];
                            asset = pathsec[2];
                            name = blobItem.Name.Substring(blobItem.Name.IndexOf($"/{asset}/") + asset.Length + 2);
                            pathBegin = string.Concat(containerName, '/', blobItem.Name.Replace(name, ""));

                            string selectedPath = (string)cbPaths.SelectedItem;
                            if (selectedPath.Equals(pathBegin))
                            {
                                clbFiles.Items.Add(name);
                            }
                        }
                    }
                }
            }
        }

        private void cbPaths_SelectedIndexChanged(object sender, EventArgs e)
        {
            this.ListFilesInBlobContainer();
        }

        private void btnGenSecUrl_Click(object sender, EventArgs e)
        {
            if ( (cbPaths.SelectedItem != null) && (clbFiles.SelectedItem != null))
            {
                string connStr = (string)(ConfigurationManager.AppSettings["prdhSASConnectionString"]);
                BlobServiceClient blobServiceClient = new BlobServiceClient(connStr);
                string selectedContainerName = ((string)cbPaths.SelectedItem).Split('/')[0];

                string blobItemName = string.Concat((string)cbPaths.SelectedItem,(string)clbFiles.SelectedItem);
                blobItemName = blobItemName.Substring(selectedContainerName.Length + 1);

                BlobClient blobClient = new BlobClient(connStr, selectedContainerName, blobItemName);
                Uri sasUri = blobClient.GenerateSasUri(
                    Azure.Storage.Sas.BlobSasPermissions.Read | Azure.Storage.Sas.BlobSasPermissions.List,
                    DateTimeOffset.UtcNow.AddHours(1)
                    );
                Console.WriteLine("SAS URI for blob is: {0}", sasUri);
                textBoxURI.Text = sasUri.ToString();

                this.SendMailWithSecureURI(selectedContainerName, blobItemName, sasUri.ToString());
            }
        }

        private async void SendMailWithSecureURI(string containerName, string mediaItem, string sasUri)
        {
            string sendMailLAUrl = (string)(ConfigurationManager.AppSettings["SendMail_LogicApp_URL"]);
            string recipient = (string)(ConfigurationManager.AppSettings["Recipient"]);
            string subject = string.Empty;
            string emailBody = string.Empty;

            subject = $"Secure URI generated for Media File : {mediaItem} ";
            emailBody = $" <br> Secure URI generated for Media File : {containerName}/{mediaItem} <br> Secure URI : {sasUri} ";
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
}
