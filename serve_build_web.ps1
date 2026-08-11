$ErrorActionPreference = "Stop"

$root = "D:\DATA\flutter_application_3\build\web"
$port = 3000

if (-not (Test-Path $root)) {
  throw "Web build folder not found: $root"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$port/")
$listener.Start()

Write-Output "Serving $root at http://127.0.0.1:$port"

$mimeTypes = @{
  ".html" = "text/html"
  ".js" = "application/javascript"
  ".mjs" = "application/javascript"
  ".css" = "text/css"
  ".json" = "application/json"
  ".png" = "image/png"
  ".jpg" = "image/jpeg"
  ".jpeg" = "image/jpeg"
  ".svg" = "image/svg+xml"
  ".ico" = "image/x-icon"
  ".txt" = "text/plain"
  ".wasm" = "application/wasm"
  ".ttf" = "font/ttf"
  ".otf" = "font/otf"
  ".map" = "application/json"
}

while ($listener.IsListening) {
  try {
    $context = $listener.GetContext()
    $requestPath = $context.Request.Url.AbsolutePath.TrimStart("/")
    if ([string]::IsNullOrWhiteSpace($requestPath)) {
      $requestPath = "index.html"
    }

    $target = Join-Path $root $requestPath
    if ((Test-Path $target) -and -not (Get-Item $target).PSIsContainer) {
      $filePath = $target
    } else {
      $filePath = Join-Path $root "index.html"
    }

    $extension = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
    $contentType = $mimeTypes[$extension]
    if (-not $contentType) {
      $contentType = "application/octet-stream"
    }

    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $response = $context.Response
    $response.StatusCode = 200
    $response.ContentType = $contentType
    $response.ContentLength64 = $bytes.Length
    $response.AddHeader("Cache-Control", "no-store, no-cache, must-revalidate")
    $response.OutputStream.Write($bytes, 0, $bytes.Length)
    $response.OutputStream.Close()
  } catch {
    try {
      if ($context -and $context.Response) {
        $context.Response.StatusCode = 500
        $payload = [System.Text.Encoding]::UTF8.GetBytes($_.Exception.Message)
        $context.Response.OutputStream.Write($payload, 0, $payload.Length)
        $context.Response.OutputStream.Close()
      }
    } catch {
    }
  }
}
