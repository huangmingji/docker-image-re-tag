#!/usr/bin/env pwsh
try {
    $tencentyun = "ccr.ccs.tencentyun.com/stargazer"
    $images = Get-Content -Path "images.json" -Raw | ConvertFrom-Json
    if (-not $images) { throw "images.json is empty or invalid" }

    foreach ($image in $images) {
        if ($image.disabled) {
            Write-Host "Skipping disabled image: $($image.name):$($image.tag)"
            continue
        }
        Write-Host "Processing image: $($image.name):$($image.tag)"

        foreach ($platform in $image.platforms) {
            $target = "$tencentyun/$($image.name):$($image.tag)"
            if ($platform -eq "linux/arm") {
                $target += "-arm"
            }
            if ($platform -eq "linux/arm64") {
                $target += "-arm64"
            }

            Write-Host "  Platform: $platform -> Target: $target"

            docker pull $($image.image) --platform=$platform
            if (-not $?) { throw "Failed to pull $($image.image) for $platform" }

            docker tag $($image.image) $target
            if (-not $?) { throw "Failed to tag $($image.image) as $target" }

            docker push $target
            if (-not $?) { throw "Failed to push $target" }
        }
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
