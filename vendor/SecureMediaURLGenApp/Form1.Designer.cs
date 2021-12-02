
namespace SecureMediaURLGenApp
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
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.textBoxURI = new System.Windows.Forms.TextBox();
            this.btnGenSecUrl = new System.Windows.Forms.Button();
            this.cbPaths = new System.Windows.Forms.ComboBox();
            this.clbFiles = new System.Windows.Forms.CheckedListBox();
            this.groupBox1.SuspendLayout();
            this.SuspendLayout();
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.textBoxURI);
            this.groupBox1.Controls.Add(this.btnGenSecUrl);
            this.groupBox1.Controls.Add(this.cbPaths);
            this.groupBox1.Controls.Add(this.clbFiles);
            this.groupBox1.Location = new System.Drawing.Point(30, 25);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(882, 575);
            this.groupBox1.TabIndex = 0;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Generate Secure Media URL";
            // 
            // textBoxURI
            // 
            this.textBoxURI.Location = new System.Drawing.Point(47, 425);
            this.textBoxURI.Multiline = true;
            this.textBoxURI.Name = "textBoxURI";
            this.textBoxURI.ReadOnly = true;
            this.textBoxURI.Size = new System.Drawing.Size(780, 64);
            this.textBoxURI.TabIndex = 6;
            // 
            // btnGenSecUrl
            // 
            this.btnGenSecUrl.Location = new System.Drawing.Point(356, 345);
            this.btnGenSecUrl.Name = "btnGenSecUrl";
            this.btnGenSecUrl.Size = new System.Drawing.Size(138, 33);
            this.btnGenSecUrl.TabIndex = 5;
            this.btnGenSecUrl.Text = "Generate Secure URL";
            this.btnGenSecUrl.UseVisualStyleBackColor = true;
            this.btnGenSecUrl.Click += new System.EventHandler(this.btnGenSecUrl_Click);
            // 
            // cbPaths
            // 
            this.cbPaths.FormattingEnabled = true;
            this.cbPaths.Location = new System.Drawing.Point(47, 60);
            this.cbPaths.Name = "cbPaths";
            this.cbPaths.Size = new System.Drawing.Size(780, 21);
            this.cbPaths.TabIndex = 1;
            this.cbPaths.SelectedIndexChanged += new System.EventHandler(this.cbPaths_SelectedIndexChanged);
            // 
            // clbFiles
            // 
            this.clbFiles.FormattingEnabled = true;
            this.clbFiles.Location = new System.Drawing.Point(47, 112);
            this.clbFiles.Name = "clbFiles";
            this.clbFiles.Size = new System.Drawing.Size(780, 214);
            this.clbFiles.TabIndex = 0;
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(952, 638);
            this.Controls.Add(this.groupBox1);
            this.Margin = new System.Windows.Forms.Padding(2);
            this.Name = "Form1";
            this.Text = "GenSecMediaUrl";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.Button btnGenSecUrl;
        private System.Windows.Forms.ComboBox cbPaths;
        private System.Windows.Forms.CheckedListBox clbFiles;
        private System.Windows.Forms.TextBox textBoxURI;
    }
}

