<#
Todo:

[ ] Translate source program into byte-code
[ ] Parse byte-code to get
	[ ] Function
	[ ] Parameters
[ ] Variable
[ ] String
[ ] Boolean
[ ] 

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

function set-var($name, $value)
{
	#Write-Host "Setting `"$name`" to $value"
	$SYMTAB[$name] = $value
}

function print-value($value)
{
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
		return $value.Substring(1, $value.length - 2)
	}

	# TODO(pebaz): Boolean
	# ???

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
	$instruction = $inst.trim().split(" ") | % { $_.trim() }

	$func = $instruction[0]
	$args = $instruction[1..($instruction.Count-1)]

	#Write-Host -ForegroundColor Green "`t$func`n`t$args"

	# TODO(pebaz): Support line comments

	return $func, $args
}

function eval($inst)
{
	$func = $inst[0]
	$args = $inst[1]

	#Write-Host -NoNewLine "INSTRUCTION: "
	#Write-Host -ForegroundColor Green $func
	
	foreach ($arg in $args)
	{
		#Write-Host -ForegroundColor Blue "`t`t$arg"
	}

	switch($func)
	{
		{ $_ -eq "set" } {
			set-var @args
		}

		{ $_ -eq "print" } {
			print-value @args
		}

		#default { Write-Host "DEFAULT" }
	}
}

$SYMTAB = @{}

ForEach ($line in $(Get-Content hello.pvm))
{
	if ($line.trim().length -gt 0)
	{
		eval(decode($line.trim()))
	}
}
