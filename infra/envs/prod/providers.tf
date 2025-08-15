provider "azurerm" { features {} }

# These are filled from AKS module outputs after apply via data source, but
# simplest is to wire directly (see below). We'll pass kubernetes providers into the app module via aliases.
