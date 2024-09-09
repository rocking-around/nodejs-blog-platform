public with sharing class GridData
{
    public List<Map<String, Object>> Data;
    public Integer Total;

    public GridData(List<Map<String, Object>> data, Integer total)
    {
        this.Data = data;
        this.Total = total;
    }
}