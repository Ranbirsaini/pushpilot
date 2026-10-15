import 'dart:io';

void main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('SERVER_READY: http://localhost:8080');
  await for (HttpRequest req in server) {
    var path = req.uri.path == '/' ? '/index.html' : req.uri.path;
    var file = File('build/web' + path.replaceAll('/', Platform.pathSeparator));
    if (!await file.exists()) {
      file = File('build/web/index.html');
    }
    if (file.path.endsWith('.html')) req.response.headers.contentType = ContentType.html;
    else if (file.path.endsWith('.js')) req.response.headers.contentType = ContentType('application', 'javascript');
    else if (file.path.endsWith('.css')) req.response.headers.contentType = ContentType('text', 'css');
    else if (file.path.endsWith('.json')) req.response.headers.contentType = ContentType.json;
    else if (file.path.endsWith('.wasm')) req.response.headers.contentType = ContentType('application', 'wasm');
    
    req.response.headers.add('Access-Control-Allow-Origin', '*');
    await file.openRead().pipe(req.response);
  }
}
