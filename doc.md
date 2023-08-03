~~~ markdown-script
# Licensed under the MIT License
# https://github.com/craigahobbs/tespo/blob/main/LICENSE

include 'powerwall.mds'


async function tespoDocMain()
    if vDoc == 'powerwall':
        typeName = 'PowerwallScenario'
    elif vDoc == 'vehicle':
        typeName = 'VehicleScenario'
    elif vDoc == 'output':
        typeName = 'TespoOutput'
    else:
        typeName = 'TespoInput'
    endif

    documentSetTitle(typeName)
    markdownPrint('[Home](#url=&var=)')
    elementModelRender(schemaElements(powerwallTypes, typeName))
endfunction


tespoDocMain()
~~~
