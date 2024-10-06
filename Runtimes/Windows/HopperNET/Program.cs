﻿using System;
using System.Globalization;
using System.Windows.Forms;

namespace HopperNET
{
    static class Program
    {
        /// <summary>
        /// The main entry point for the application.
        /// </summary>
        [STAThread]
        static void Main()
        {
            try
            {
                CultureInfo.CurrentCulture = new CultureInfo("en-US");

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);

                Application.Run(new Hopper());
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.StackTrace.ToString(), "Hopper Exception:" + ex.Message);
            }
        }
    }
}
