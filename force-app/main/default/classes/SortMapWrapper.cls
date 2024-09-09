public with sharing class SortMapWrapper implements Comparable
{
    public String SortField;
    public String SorfDirection;
    public Map<String, Object> M;

    public SortMapWrapper(String sortField, String sorfDirection, Map<String, Object> m)
    {
        this.SortField = sortField;
        this.SorfDirection = sorfDirection;
        this.M = m;
    }

    public Integer compareTo(Object objToCompare) {
        SortMapWrapper wrapper = (SortMapWrapper)objToCompare;

        Integer result;
        
        String value1 = M.get(SortField)?.toString();
        String value2 = wrapper.M.get(SortField)?.toString();

        if (value1 == value2)
            result = 0;
        else if (value1 > value2)
            result = 1;
        else
            result = -1;
            
        if (SorfDirection != 'asc')
            result = -result;

        return result;
    }
}