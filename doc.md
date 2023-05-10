~~~ markdown-script
# Licensed under the MIT License
# https://github.com/craigahobbs/tespo/blob/main/LICENSE

include 'powerwall.mds'


async function tespoDocMain()
    if vDoc == 'powerwall' then
        typeName = 'PowerwallScenario'
    else if vDoc == 'vehicle' then
        typeName = 'VehicleScenario'
    else if vDoc == 'output' then
        typeName = 'TespoOutput'
    else then
        typeName = 'TespoInput'
    endif

    setDocumentTitle(typeName)
    markdownPrint('[Home](#url=&var=)')
    elementModelRender(schemaElements(powerwallTypes, typeName))
endfunction


tespoDocMain()
~~~
