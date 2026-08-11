$ErrorActionPreference = 'Stop'

param(
  [string]$BaseUrl = 'http://127.0.0.1:8001',
  [string]$OutputPath = 'D:\DATA\ECG_MODEL_V15_FINAL\validation_results.json'
)

$records = @(
  @{ dir = '100'; name = '00001_lr' },
  @{ dir = '100'; name = '00002_lr' },
  @{ dir = '100'; name = '00003_lr' },
  @{ dir = '500'; name = '00001_hr' },
  @{ dir = '500'; name = '00002_hr' }
)

$health = curl.exe -s "$BaseUrl/health" | ConvertFrom-Json
$results = @()

foreach ($record in $records) {
  $heaPath = "D:/DATA/$($record.dir)/$($record.name).hea"
  $datPath = "D:/DATA/$($record.dir)/$($record.name).dat"
  $heaHash = (Get-FileHash $heaPath -Algorithm SHA256).Hash
  $datHash = (Get-FileHash $datPath -Algorithm SHA256).Hash
  $response = curl.exe -s -X POST "$BaseUrl/analyze_files" -F "files=@$heaPath" -F "files=@$datPath" | ConvertFrom-Json
  $wave = @($response.graphData.waveform)
  $wavePreview = @()
  if ($wave.Count -gt 0) {
    $limit = [Math]::Min(15, $wave.Count)
    $wavePreview = $wave[0..($limit - 1)]
  }
  $results += [pscustomobject]@{
    record = $record.name
    hea_sha256 = $heaHash
    dat_sha256 = $datHash
    analysis_id = $response.analysisId
    recording_id = $response.recordingId
    score = $response.modelScore
    risk_level = $response.riskLevel
    classification = $response.classification
    bpm = $response.bpm
    signal_quality = $response.signalQuality
    region = $response.region
    active_coils = @($response.activeCoils)
    waveform_preview = $wavePreview
  }
}

$payload = [ordered]@{
  generated_on = (Get-Date).ToString('s')
  base_url = $BaseUrl
  health = $health
  results = $results
}

$payload | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Output "Saved validation to $OutputPath"
