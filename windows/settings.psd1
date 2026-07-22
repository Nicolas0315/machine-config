@{
    Registry = @(
        @{
            Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            Name = 'HideFileExt'
            Type = 'DWord'
            Value = 0
            Description = 'Show known file extensions'
        }
        @{
            Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            Name = 'Hidden'
            Type = 'DWord'
            Value = 1
            Description = 'Show hidden files'
        }
        @{
            Path = 'HKCU:\Console'
            Name = 'VirtualTerminalLevel'
            Type = 'DWord'
            Value = 1
            Description = 'Enable virtual terminal sequences'
        }
    )

    Git = @{
        'init.defaultBranch' = 'main'
        'pull.ff' = 'only'
        'core.autocrlf' = 'input'
    }
}
