public abstract class IManageWrapBase {
  protected IManageWrapBase(Object item) {
    wrapItem = item;
    children = new List<Object>();
  }

  public Object wrapItem { get; set; }

  public List<Object> children { get; private set; }
}