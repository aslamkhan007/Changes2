namespace CEIHaryana.Industry_Master.Services
{
    public interface IIndustryBasicCafProcessor
    {
        void ProcessFromStoredProcedure(string storedProcedureName, string cafPinColumnName = "cafPin");
    }
}
