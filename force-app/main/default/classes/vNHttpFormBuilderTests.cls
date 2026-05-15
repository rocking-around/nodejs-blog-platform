@isTest
private class vNHttpFormBuilderTests {
  @isTest
  private static void GetContentTypeTest() {
    String contentType = vNHttpFormBuilder.GetContentType();
    System.assert(
      contentType ==
      'multipart/form-data; boundary=8b35acb2267c40cda4643792183d0ded',
      ''
    );
  }

  @isTest
  private static void WriteBoundaryTest() {
    String contentType = vNHttpFormBuilder.WriteBoundary();
    System.assert(
      contentType == 'LS04YjM1YWNiMjI2N2M0MGNkYTQ2NDM3OTIxODNkMGRlZA0K',
      ''
    );

    contentType = vNHttpFormBuilder.WriteBoundary(
      vNHttpFormBuilder.EndingType.Cr,
      false
    );
    System.assert(
      contentType == 'Ci0tOGIzNWFjYjIyNjdjNDBjZGE0NjQzNzkyMTgzZDBkZWQNCg0K',
      ''
    );

    contentType = vNHttpFormBuilder.WriteBoundary(
      vNHttpFormBuilder.EndingType.None,
      false
    );
    System.assert(
      contentType == 'DQotLThiMzVhY2IyMjY3YzQwY2RhNDY0Mzc5MjE4M2QwZGVkDQoN',
      ''
    );

    contentType = vNHttpFormBuilder.WriteBoundary(
      vNHttpFormBuilder.EndingType.Cr,
      true
    );
    System.assert(
      contentType == 'Ci0tOGIzNWFjYjIyNjdjNDBjZGE0NjQzNzkyMTgzZDBkZWQtLQ0K',
      ''
    );

    contentType = vNHttpFormBuilder.WriteBoundary(
      vNHttpFormBuilder.EndingType.None,
      true
    );
    System.assert(
      contentType == 'DQotLThiMzVhY2IyMjY3YzQwY2RhNDY0Mzc5MjE4M2QwZGVkLS0NCg0K',
      ''
    );
  }

  public static void WriteFileTest() {
    String key = 'TEST';
    String value = 'TEST.txt';
    String mimeType = 'text';
    blob fileBlob = blob.valueOf('TEST');

    vNHttpFormBuilder.WriteFileResult result = vNHttpFormBuilder.WriteFile(
      key,
      value,
      mimeType,
      fileBlob,
      true
    );

    System.assert(
      result.Content ==
      'Q29udGVudC1EaXNwb3NpdGlvbjogZm9ybS1kYXRhOyBuYW1lPSJURVNUIjsgZmlsZW5hbWU9IlRFU1QudHh0Ig0KQ29udGVudC1UeXBlOiB0ZXh0ICANCg0KVEVTVA0K',
      ''
    );
  }
}