<#
Todo:

[✔] Translate source program into byte-code
[✔] Parse byte-code to get
	[✔] Function
	[✔] Parameters
[✔] Variable
[✔] String
[✔] Boolean
[✔] Int
[✔] Float
[✔] Line Comment

	decl name
	set name "Pebaz"

	call print name ->

	decl age
	set age 23

	call add 1 age -> age

	proc bubbles
		call print "Bubbles!" ->
	ret None
#>

param (
	[Parameter(Mandatory=$false)][string]$filename
)

function set-var($name, $value)
{
	#Write-Host -ForegroundColor Red "Setting `"$name`" to $value"
	$SYMTAB[$name] = $value
}

function print-value($value)
{
	Write-Host $(eval-value($value))
}

function prin-value($value)
{
	Write-Host -NoNewLine $(eval-value($value))
}

function eval-value($value)
{
	# Variable Name String (e.g. `name`)
	if ($value -is [String] -and !($value.StartsWith("`"")))
	{
		return lookup($value)
	}

	# Pure String (e.g. `"Pebaz"`)
	elseif ($value -is [String])
	{
		return $value.Substring(1, $value.length - 2).replace('\s', ' ').replace('\n', "`n")
	}

	# Other Values (e.g. 123)
	else
	{
		return $value
	}
}

function lookup($name)
{
	if (!($name.StartsWith("`"")))
	{
		$value = $SYMTAB[$name]

		if ($value)
		{
			if ($value -is [String] -and !($value.StartsWith("`"")))
			{
				return lookup($value)
			}
			else
			{
				return eval-value($value)
			}
		}
		else
		{
			Write-Host -ForegroundColor Red "[Undefined Variable][Line: $LINE_NUM]"
			Write-Host -ForegroundColor Red "    No value assigned to variable: `"$name`""
		}
	}
}

function decode($inst)
{
	# TODO(pebaz): Make sure this does not strip strings
	$instruction = $inst.trim().split(" ") #| % { $_.trim() }

	$instructions = @()
	$stringed = $False
	$string_buffer = ""

	# Gather all strings
	foreach ($i in $instruction)
	{
		if ($i.length -eq 0) { continue }

		if ($i.startswith('"'))
		{
			# Write-Host -ForegroundColor Cyan "STRING START `"$i`""
			$stringed = $True
		}

		if ($i.endswith('"'))
		{
			# Write-Host -ForegroundColor Cyan "STRING END   `"$i`""
			$stringed = $False
		}

		if ($stringed)
		{
			$string_buffer += $i
		}
		else
		{
			#$instructions += if ($string_buffer.length -gt 0) { $string_buffer } else { $i }
			$string_buffer += $i
			$instructions += $string_buffer
			$string_buffer = ""
		}
	}

	$func = $instructions[0]
	$args = $instructions[1..($instructions.Count-1)]

	$values = @()

	<# Each arg can only be one of:
	 - String
	 - Number (Int/Float)
	 - Boolean
	 - Variable
	#>

	foreach ($i in $args)
	{
		# In-Line Comment
		if ($i.startswith("%%"))
		{
			break
		}

		# String
		elseif ($i -match '^".*"$')
		{
			$values += $i
		}

		# Float
		elseif ($i -match '^[+-]?([0-9]*)?\.[0-9]+$')
		{
			$values += [Float]$i
		}

		# Int
		elseif ($i -match '^[+-]?[0-9]+$')
		{
			$values += [Int]$i
		}

		# Boolean
		elseif ($i -cmatch '^TRUE|FALSE$')
		{
			$values += [Boolean]$i
		}

		# Variable name
		elseif ($i -match '^[_a-z]*[_a-z0-9]+$')
		{
			$values += $i
		}

		else
		{
			Write-Host -ForegroundColor Red "[Invalid Syntax][Line: $LINE_NUM]"
			Write-Host -ForegroundColor Red "    Error Parsing: `"$i`""
		}
	}

	#Write-Host -ForegroundColor Green "`t$func`n`t$args"

	# TODO(pebaz): Support line comments

	return $func, $values
}

function func-add($a, $b, $result)
{
	# Write-Host -ForegroundColor Cyan "FUNC ADD: $r"
	# Write-Host $a $(eval-value($a))
	# Write-Host $b $(eval-value($b))

	$r = $(eval-value($a)) + $(eval-value($b))
	$args = @($result, $($r))
	set-var @args

	# Write-Host "Result: $r Stored in $result"
}

function func-sub($a, $b, $result)
{
	# Write-Host -ForegroundColor Cyan "FUNC ADD: $r"
	# Write-Host $a $(eval-value($a))
	# Write-Host $b $(eval-value($b))

	$r = $(eval-value($a)) - $(eval-value($b))
	$args = @($result, $($r))
	set-var @args

	# Write-Host "Result: $r Stored in $result"
}

function func-mul($a, $b, $result)
{
	# Write-Host -ForegroundColor Cyan "FUNC ADD: $r"
	# Write-Host $a $(eval-value($a))
	# Write-Host $b $(eval-value($b))

	$r = $(eval-value($a)) * $(eval-value($b))
	$args = @($result, $($r))
	set-var @args

	# Write-Host "Result: $r Stored in $result"
}

function func-div($a, $b, $result)
{
	# Write-Host -ForegroundColor Cyan "FUNC ADD: $r"
	# Write-Host $a $(eval-value($a))
	# Write-Host $b $(eval-value($b))

	$r = $(eval-value($a)) / $(eval-value($b))
	$args = @($result, $($r))
	set-var @args

	# Write-Host "Result: $r Stored in $result"
}

function func-help($topic)
{
	Write-Host "`nHouse Programming Language v0.1.0"
	$topics = @(
		"    set <name> <value>",
		"    print ( <name> | <value> )",
		"    prin ( <name> | <value> )",
		"    add <a> <b> <store-in-var-name>",
		"    sub <a> <b> <store-in-var-name>",
		"    mul <a> <b> <store-in-var-name>",
		"    div <a> <b> <store-in-var-name>",
		"    help",
		"    exit"
	)

	foreach ($t in $topics)
	{
		Write-Host $t -ForegroundColor Cyan
	}
}

function eval($inst)
{
	$func = $inst[0]
	$args = $inst[1]

	#Write-Host -NoNewLine "INSTRUCTION: "
	#Write-Host -ForegroundColor Green $func
	# foreach ($arg in $args)
	# {
	# 	Write-Host -ForegroundColor Blue "`t`t$arg"
	# }

	switch($func)
	{
		{ $_ -eq "set" } { set-var @args }
		{ $_ -eq "print" } { print-value @args }
		{ $_ -eq "prin" } { prin-value @args }
		{ $_ -eq "add" } { func-add @args }
		{ $_ -eq "sub" } { func-sub @args }
		{ $_ -eq "mul" } { func-mul @args }
		{ $_ -eq "div" } { func-div @args }
		{ $_ -eq "help" } { func-help @args }
		{ $_ -eq "exit" } { exit }

		default {
			Write-Host -ForegroundColor Red "[Invalid Instruction][Line: $LINE_NUM]"
			Write-Host -ForegroundColor Red "    No Instruction Named: `"$_`""
		}
	}
}

$SYMTAB = @{}
$LINE_NUM = 0


if ($filename.Length -ne 0)
{
	ForEach ($line in $(Get-Content $filename))
	{
		$LINE_NUM += 1

		if ($line.trim().startswith("%%"))
		{
			continue
		}
		elseif ($line.trim().length -gt 0)
		{
			eval(decode($line.trim()))
		}
	}
}
else
{
	while ($true)
	{
		Write-Host -NoNewLine ">>> "
		$line = [Console]::ReadLine()
		eval(decode($line.trim()))
	}
}
