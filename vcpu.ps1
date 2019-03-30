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
	[Parameter(Mandatory=$true)][string]$filename
)

function set-var($name, $value)
{
	#Write-Host "Setting `"$name`" to $value"
	$SYMTAB[$name] = $value
}

function print-value($value)
{
	Write-Host $(eval-value($value))
	return

	if ($value -is [String] -and !($value.StartsWith("`"")))
	{
		Write-Host $(eval-value($value))
	}
	elseif ($value -is [String])
	{
		Write-Host $value.Substring(1, $value.length - 2)
	}
	else
	{
		Write-Host $value
	}
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

		if ($value -is [String] -and !($value.StartsWith("`"")))
		{
			return lookup($value)
		}
		else
		{
			return eval-value($value)
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
		elseif ($i -match '^[_a-z][_a-z0-9]+$')
		{
			$values += $i
		}

		else
		{
			Write-Host -ForegroundColor Red "[Invalid Syntax][Line: $LINE_NUM]"
			Write-Host -ForegroundColor Red "    Error Parsing: `"$i`""
			exit
		}
	}

	#Write-Host -ForegroundColor Green "`t$func`n`t$args"

	# TODO(pebaz): Support line comments

	return $func, $values
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
		{ $_ -eq "set" } {
			set-var @args
		}

		{ $_ -eq "print" } {
			print-value @args
		}
	}
}

$SYMTAB = @{}
$LINE_NUM = 0

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
