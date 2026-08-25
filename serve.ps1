$root = Split-Path -Parent $PSScriptRoot
$port = 8080
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Host "Serving $root on http://localhost:$port/"

$mimeMap = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".webp" = "image/webp"
    ".woff" = "font/woff"
    ".woff2"= "font/woff2"
    ".mp4"  = "video/mp4"
    ".pdf"  = "application/pdf"
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    try {
        $urlPath = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath)
        if ($urlPath -eq "/") { $urlPath = "/index.html" }
        $filePath = Join-Path $root ($urlPath.TrimStart("/"))

        if (Test-Path $filePath -PathType Container) {
            $filePath = Join-Path $filePath "index.html"
        }

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = $mimeMap[$ext]
            if (-not $contentType) { $contentType = "application/octet-stream" }
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
            $notFound = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $urlPath")
            $response.OutputStream.Write($notFound, 0, $notFound.Length)
        }
    } catch {
        $response.StatusCode = 500
        $errBytes = [System.Text.Encoding]::UTF8.GetBytes("500 Server Error: $_")
        $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
    } finally {
        $response.OutputStream.Close()
    }
}
