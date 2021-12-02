
namespace VendorClientApp
{
    partial class Form1
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.ComponentModel.ComponentResourceManager resources = new System.ComponentModel.ComponentResourceManager(typeof(Form1));
            this.lbUpload = new System.Windows.Forms.CheckedListBox();
            this.lbDownload = new System.Windows.Forms.CheckedListBox();
            this.btnUpload = new System.Windows.Forms.Button();
            this.btnDownload = new System.Windows.Forms.Button();
            this.btnPlay = new System.Windows.Forms.Button();
            this.btnRefreshLocalFilesList = new System.Windows.Forms.Button();
            this.btnRefreshBlobFilesList = new System.Windows.Forms.Button();
            this.upBtnPlay = new System.Windows.Forms.Button();
            this.cbDownload = new System.Windows.Forms.ComboBox();
            this.cbUpload = new System.Windows.Forms.ComboBox();
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.ctrlWMP = new AxWMPLib.AxWindowsMediaPlayer();
            this.groupBox2 = new System.Windows.Forms.GroupBox();
            this.groupBox3 = new System.Windows.Forms.GroupBox();
            this.groupBox1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.ctrlWMP)).BeginInit();
            this.groupBox2.SuspendLayout();
            this.groupBox3.SuspendLayout();
            this.SuspendLayout();
            // 
            // lbUpload
            // 
            this.lbUpload.FormattingEnabled = true;
            this.lbUpload.Location = new System.Drawing.Point(15, 90);
            this.lbUpload.Name = "lbUpload";
            this.lbUpload.Size = new System.Drawing.Size(348, 154);
            this.lbUpload.TabIndex = 0;
            // 
            // lbDownload
            // 
            this.lbDownload.FormattingEnabled = true;
            this.lbDownload.Location = new System.Drawing.Point(13, 94);
            this.lbDownload.Name = "lbDownload";
            this.lbDownload.Size = new System.Drawing.Size(343, 154);
            this.lbDownload.TabIndex = 2;
            // 
            // btnUpload
            // 
            this.btnUpload.Location = new System.Drawing.Point(299, 271);
            this.btnUpload.Name = "btnUpload";
            this.btnUpload.Size = new System.Drawing.Size(63, 23);
            this.btnUpload.TabIndex = 4;
            this.btnUpload.Text = "Upload";
            this.btnUpload.UseVisualStyleBackColor = true;
            this.btnUpload.Click += new System.EventHandler(this.btnUpload_Click);
            // 
            // btnDownload
            // 
            this.btnDownload.Location = new System.Drawing.Point(292, 275);
            this.btnDownload.Name = "btnDownload";
            this.btnDownload.Size = new System.Drawing.Size(63, 23);
            this.btnDownload.TabIndex = 5;
            this.btnDownload.Text = "Download";
            this.btnDownload.UseVisualStyleBackColor = true;
            this.btnDownload.Click += new System.EventHandler(this.btnDownload_Click);
            // 
            // btnPlay
            // 
            this.btnPlay.Location = new System.Drawing.Point(151, 271);
            this.btnPlay.Name = "btnPlay";
            this.btnPlay.Size = new System.Drawing.Size(63, 23);
            this.btnPlay.TabIndex = 7;
            this.btnPlay.Text = "Play";
            this.btnPlay.UseVisualStyleBackColor = true;
            this.btnPlay.Click += new System.EventHandler(this.btnPlay_Click);
            // 
            // btnRefreshLocalFilesList
            // 
            this.btnRefreshLocalFilesList.Location = new System.Drawing.Point(15, 271);
            this.btnRefreshLocalFilesList.Name = "btnRefreshLocalFilesList";
            this.btnRefreshLocalFilesList.Size = new System.Drawing.Size(63, 23);
            this.btnRefreshLocalFilesList.TabIndex = 8;
            this.btnRefreshLocalFilesList.Text = "Refresh";
            this.btnRefreshLocalFilesList.UseVisualStyleBackColor = true;
            this.btnRefreshLocalFilesList.Click += new System.EventHandler(this.btnRefreshLocalFilesList_Click);
            // 
            // btnRefreshBlobFilesList
            // 
            this.btnRefreshBlobFilesList.Location = new System.Drawing.Point(13, 275);
            this.btnRefreshBlobFilesList.Name = "btnRefreshBlobFilesList";
            this.btnRefreshBlobFilesList.Size = new System.Drawing.Size(63, 23);
            this.btnRefreshBlobFilesList.TabIndex = 9;
            this.btnRefreshBlobFilesList.Text = "Refresh";
            this.btnRefreshBlobFilesList.UseVisualStyleBackColor = true;
            this.btnRefreshBlobFilesList.Click += new System.EventHandler(this.btnRefreshBlobFilesList_Click);
            // 
            // upBtnPlay
            // 
            this.upBtnPlay.Location = new System.Drawing.Point(158, 275);
            this.upBtnPlay.Margin = new System.Windows.Forms.Padding(2, 2, 2, 2);
            this.upBtnPlay.Name = "upBtnPlay";
            this.upBtnPlay.Size = new System.Drawing.Size(63, 23);
            this.upBtnPlay.TabIndex = 10;
            this.upBtnPlay.Text = "Play";
            this.upBtnPlay.UseVisualStyleBackColor = true;
            this.upBtnPlay.Click += new System.EventHandler(this.Play_Click);
            // 
            // cbDownload
            // 
            this.cbDownload.FormattingEnabled = true;
            this.cbDownload.Location = new System.Drawing.Point(13, 51);
            this.cbDownload.Margin = new System.Windows.Forms.Padding(2, 2, 2, 2);
            this.cbDownload.Name = "cbDownload";
            this.cbDownload.Size = new System.Drawing.Size(343, 21);
            this.cbDownload.TabIndex = 11;
            this.cbDownload.SelectedIndexChanged += new System.EventHandler(this.cbDownload_SelectedIndexChanged);
            // 
            // cbUpload
            // 
            this.cbUpload.FormattingEnabled = true;
            this.cbUpload.Location = new System.Drawing.Point(15, 47);
            this.cbUpload.Margin = new System.Windows.Forms.Padding(2, 2, 2, 2);
            this.cbUpload.Name = "cbUpload";
            this.cbUpload.Size = new System.Drawing.Size(348, 21);
            this.cbUpload.TabIndex = 12;
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.cbDownload);
            this.groupBox1.Controls.Add(this.upBtnPlay);
            this.groupBox1.Controls.Add(this.lbDownload);
            this.groupBox1.Controls.Add(this.btnRefreshBlobFilesList);
            this.groupBox1.Controls.Add(this.btnDownload);
            this.groupBox1.Location = new System.Drawing.Point(17, 23);
            this.groupBox1.Margin = new System.Windows.Forms.Padding(2, 2, 2, 2);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Padding = new System.Windows.Forms.Padding(2, 2, 2, 2);
            this.groupBox1.Size = new System.Drawing.Size(376, 330);
            this.groupBox1.TabIndex = 13;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Files on Cloud";
            // 
            // ctrlWMP
            // 
            this.ctrlWMP.Dock = System.Windows.Forms.DockStyle.Fill;
            this.ctrlWMP.Enabled = true;
            this.ctrlWMP.Location = new System.Drawing.Point(2, 15);
            this.ctrlWMP.Name = "ctrlWMP";
            this.ctrlWMP.OcxState = ((System.Windows.Forms.AxHost.State)(resources.GetObject("ctrlWMP.OcxState")));
            this.ctrlWMP.Size = new System.Drawing.Size(477, 209);
            this.ctrlWMP.TabIndex = 6;
            //this.ctrlWMP.Enter += new System.EventHandler(this.ctrlWMP_Enter);
            // 
            // groupBox2
            // 
            this.groupBox2.Controls.Add(this.ctrlWMP);
            this.groupBox2.Location = new System.Drawing.Point(175, 367);
            this.groupBox2.Margin = new System.Windows.Forms.Padding(2, 2, 2, 2);
            this.groupBox2.Name = "groupBox2";
            this.groupBox2.Padding = new System.Windows.Forms.Padding(2, 2, 2, 2);
            this.groupBox2.Size = new System.Drawing.Size(481, 226);
            this.groupBox2.TabIndex = 14;
            this.groupBox2.TabStop = false;
            // 
            // groupBox3
            // 
            this.groupBox3.Controls.Add(this.cbUpload);
            this.groupBox3.Controls.Add(this.lbUpload);
            this.groupBox3.Controls.Add(this.btnPlay);
            this.groupBox3.Controls.Add(this.btnRefreshLocalFilesList);
            this.groupBox3.Controls.Add(this.btnUpload);
            this.groupBox3.Location = new System.Drawing.Point(417, 27);
            this.groupBox3.Margin = new System.Windows.Forms.Padding(2, 2, 2, 2);
            this.groupBox3.Name = "groupBox3";
            this.groupBox3.Padding = new System.Windows.Forms.Padding(2, 2, 2, 2);
            this.groupBox3.Size = new System.Drawing.Size(370, 326);
            this.groupBox3.TabIndex = 15;
            this.groupBox3.TabStop = false;
            this.groupBox3.Text = "Files to Upload to Cloud";
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(800, 653);
            this.Controls.Add(this.groupBox3);
            this.Controls.Add(this.groupBox2);
            this.Controls.Add(this.groupBox1);
            this.Name = "Form1";
            this.Text = "Vendor Client";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.groupBox1.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.ctrlWMP)).EndInit();
            this.groupBox2.ResumeLayout(false);
            this.groupBox3.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.CheckedListBox lbUpload;
        private System.Windows.Forms.CheckedListBox lbDownload;
        private System.Windows.Forms.Button btnUpload;
        private System.Windows.Forms.Button btnDownload;
        private System.Windows.Forms.Button btnPlay;
        private System.Windows.Forms.Button btnRefreshLocalFilesList;
        private System.Windows.Forms.Button btnRefreshBlobFilesList;
        private System.Windows.Forms.Button upBtnPlay;
        private System.Windows.Forms.ComboBox cbDownload;
        private System.Windows.Forms.ComboBox cbUpload;
        private System.Windows.Forms.GroupBox groupBox1;
        private AxWMPLib.AxWindowsMediaPlayer ctrlWMP;
        private System.Windows.Forms.GroupBox groupBox2;
        private System.Windows.Forms.GroupBox groupBox3;
    }
}

