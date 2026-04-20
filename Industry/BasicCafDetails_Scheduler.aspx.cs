using CEIHaryana.Industry_Master.Services;
using System;
using System.Web.UI;

namespace CEIHaryana.Industry
{
    public partial class BasicCafDetails_Scheduler : System.Web.UI.Page
    {
        private readonly IIndustryBasicCafProcessor basicCafProcessor = new IndustryBasicCafProcessor();

        private const string CafSourceStoredProcedureName = "sp_Industry_GetCafPinList_ForBasicCafDetails";
        private const string CafPinColumnName = "cafPin";

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                ProcessBasicCafDetails();
                hfTaskCompleted.Value = "true";
            }
        }

        private void ProcessBasicCafDetails()
        {
            try
            {
                basicCafProcessor.ProcessFromStoredProcedure(CafSourceStoredProcedureName, CafPinColumnName);
            }
            catch (Exception ex)
            {
                ScriptManager.RegisterStartupScript(this, this.GetType(), "showalert", $"alert('{ex.Message}')", true);
            }
        }
    }
}
