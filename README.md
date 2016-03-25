## datapack
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/datapack)](https://cran.r-project.org/package=datapack)

- **Author**: Matthew B. Jones and Peter Slaughter ([NCEAS](http://www.nceas.ucsb.edu))
- [doi:10.5063/F1QV3JGM](http://doi.org/10.5063/F1QV3JGM)
- **License**: [Apache 2](http://opensource.org/licenses/Apache-2.0)
- [Package source code on Github](https://github.com/ropensci/datapack)
- [**Submit Bugs and feature requests**](https://github.com/ropensci/datapack/issues)

The datapack R package provides an abstraction for collating 
heterogeneous collections of data objects and metadata into a bundle that can 
be transported and loaded into a single composite file.  The methods in 
this package provide a convenient way to load data from common repositories 
such as DataONE into the R environment, and to document, serialize, and save 
data from R to data repositories worldwide.

## Installation Notes 

The *datapack* R package requires the R package *redland*,  which requires the Redland C libraries. 
The following instructions illustrate how to install *datapack* and its requirements.

### Installing on Mac OS X

On Mac OS X, the required Redland C libraries can be installed with either [Mac Ports](https://www.macports.org) package manager
or the [HomeBrew](http://brew.sh) package manager. The HomeBrew package manager can be significantly faster to install
but either one will work provided the directions shown below are followed.

You can check if you have MacPorts installed by entering the following command in a terminal window:

```
port version
```

If the *port* command is not found, then skip to the [Installing with HomeBrew](#homebrew) section.

### Mac OS X install option 1: install using Macports
If you are already using the MacPorts package manager, you can install *datapack* with the following commands, 
otherwise, it is recommended that you skip to the next section [Installing with HomeBrew](#homebrew). 

To install the *datapack* R package with MacPorts, enter this commands at a terminal window:
```
sudo port install redland
```

Then enter these commands in the R console:
```
install.packages("redland", type="source")
install.packages("datapack")
library(datapack)
```

Please note that the *install.packages* command specifies a "source" installation. Installing from
source is only necessary if Macports is being used, and is not a requirement if Homebrew is used.

The *datapack* R package should be available for use at this point

### <a id="homebrew"></a> Mac OS X install option 2: install using HomeBrew

On Mac OS X you can use the package management system [HomeBrew](http://brew.sh) to install the 
necessary libraries. The HomeBrew software can be installed with the following command entered at a terminal window:

```
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Once HomeBrew has been installed, you can then enter the following command in a terminal windows to install the Redland C libraries:

```
brew install redland
```

Next, install the *datapack* R package with these commands typed at the R console window:

```
install.packages("datapack")
library(datapack)
```
 
The *datapack* R package should be available for use at this point

## Installing on Ubuntu

For ubuntu, install the required Redland C libraries by entering the following commands 
in a terminal window:

```
sudo apt-get update
sudo apt-get install librdf0 librdf0-dev
```

Then install the R packages from the R console:

```
install.packages("datapack")
library(datapack)
```

The *datapack* R package should be available for use at this point

## Installing on Windows

For windows, the required redland R package is distributed as a binary release, so it is not
necessary to install any additional system libraries.

To install the R packages from the R console:

```
install.packages("datapack")
library(datapack)
```

## Quick Start

See the full manual for documentation, but once installed, the package can be run in R using:

```
library(datapack)
help("datapack")
```

Create a DataPackage and add metadata and science data DataObjects to it:

```
library(datapack)
library(uuid)
dp <- new("DataPackage")
mdFile <- system.file("extdata/sample-eml.xml", package="datapack")
mdId <- paste("urn:uuid:", UUIDgenerate(), sep="")
md <- new("DataObject", id=mdId, format="eml://ecoinformatics.org/eml-2.1.0", file=mdFile)
addData(dp, md)

csvfile <- system.file("extdata/sample-data.csv", package="datapack")
sciId <- paste("urn:uuid:", UUIDgenerate(), sep="")
sciObj <- new("DataObject", id=sciId, format="text/csv", filename=csvfile)
dp <- addData(dp, sciObj)
ids <- getIdentifiers(dp)
```

Add a relationship to the DataPackage that shows that the metadata describes, or "documents", the science data:

```
dp <- insertRelationship(dp, subjectID=mdId, objectIDs=sciId)
relations <- getRelationships(dp)
```  

Create an Resource Description Framework representation of the relationships in the package:

```
serializationId <- paste("resourceMap", UUIDgenerate(), sep="")
filePath <- file.path(sprintf("%s/%s.rdf", tempdir(), serializationId))
status <- serializePackage(dp, filePath, id=serializationId, resolveURI="")
```  
Save the DataPackage to a file, using the BagIt packaging format:

```
bagitFile <- serializeToBagIt(dp) 
```

Note that the *dataone* R package can be used to upload a DataPackage to a DataONE Member Node
using the *uploadDataPackage* method. Please see the documentation for the *dataone* R package,
for example:

```
vignette("upload-data", package="dataone")
```

[![nceas_footer](https://www.nceas.ucsb.edu/files/newLogo_0.png)](http://www.nceas.ucsb.edu)

[![ropensci_footer](http://ropensci.org/public_images/github_footer.png)](http://ropensci.org)