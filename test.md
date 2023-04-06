# Test

~~~ markdown-script
include 'tesla.mds'

scenario = teslaLoadPowerwallScenario('data/2023-03-seattle.json')

markdownPrint('~~~', jsonStringify(scenario, 4), '~~~')
~~~
