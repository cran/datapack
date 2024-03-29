#
#   This work was created by participants in the DataONE project, and is
#   jointly copyrighted by participating institutions in DataONE. For
#   more information on DataONE, see our web site at http://dataone.org.
#
#     Copyright 2011-2015
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

#' DataObject wraps raw data with system-level metadata
#' @description DataObject is a wrapper class that associates raw data or a data file with system-level metadata 
#' describing the data.  The system metadata includes attributes such as the object's identifier, 
#' type, size, checksum, owner, version relationship to other objects, access rules, and other critical metadata.
#' The SystemMetadata is compliant with the DataONE federated repository network's definition of SystemMetadata, and
#' is encapsulated as a separate object of type \code{\link{SystemMetadata}} that can be manipulated as needed. Additional science-level and
#' domain-specific metadata is out-of-scope for SystemMetadata, which is intended only for critical metadata for
#' managing objects in a repository system.
#' @details   
#' A DataObject can be constructed by passing the data and SystemMetadata to the new() method, or by passing
#' an identifier, data, format, user, and DataONE node identifier, in which case a SystemMetadata instance will
#' be generated with these fields and others that are calculated (such as size and checksum).
#' 
#' Data are associated with the DataObject either by passing it as a \code{'raw'} value to the \code{'dataobj'}
#' parameter in the constructor, which is then stored in memory, or by passing a fully qualified file path to the 
#' data in the \code{'filename'} parameter, which is then stored on disk.  One of dataobj or filename is required.
#' Use the \code{'filename'} approach when data are too large to be managed effectively in memory.  Callers can
#' access the \code{'filename'} slot to get direct access to the file, or can call \code{'getData()'} to retrieve the
#' contents of the data or file as a raw value (but this will read all of the data into memory).
#' @slot sysmeta A value of type \code{"SystemMetadata"}, containing the metadata about the object
#' @slot data A value of type \code{"raw"}, containing the data represented in this object
#' @slot filename A character value that contains the fully-qualified path to the object data on disk
#' @slot dataURL A character value for the URL used to load data into this DataObject
#' @slot updated A list containing logical values which indicate if system metadata or the data object have been updated since object creation.
#' @slot oldId A character string containing the previous identifier used, before a \code{"replaceMember"} call.
#' @slot targetPath An optional character string holding the path of where the file is placed in a downloaded package.
#' @rdname DataObject-class
#' @keywords classes
#' @import methods
#' @include dmsg.R
#' @include SystemMetadata.R
#' @aliases DataObject-class
#' @section Methods:
#' \itemize{
#'   \item{\code{\link[=DataObject-initialize]{initialize}}}{: Initialize a DataObject}
#'   \item{\code{\link{addAccessRule}}}{: Add a Rule to the AccessPolicy}
#'   \item{\code{\link{canRead}}}{: Test whether the provided subject can read an object.}
#'   \item{\code{\link{getData}}}{: Get the data content of a specified data object}
#'   \item{\code{\link{getFormatId}}}{: Get the FormatId of the DataObject}
#'   \item{\code{\link{getIdentifier}}}{: Get the Identifier of the DataObject}
#'   \item{\code{\link{hasAccessRule}}}{: Determine if an access rules exists for a DataObject.}
#'   \item{\code{\link{setPublicAccess}}}{: Add a Rule to the AccessPolicy to make the object publicly readable.}
#'   \item{\code{\link{updateXML}}}{: Update selected elements of the xml content of a DataObject}
#' }
#' @seealso \code{\link{datapack}}
#' @examples
#' data <- charToRaw("1,2,3\n4,5,6\n")
#' targetPath <- "myData/time-trials/trial_data.csv"
#' do <- new("DataObject", "id1", dataobj=data, "text/csv", 
#'   "uid=jones,DC=example,DC=com", "urn:node:KNB", targetPath=targetPath)
#' getIdentifier(do)
#' getFormatId(do)
#' getData(do)
#' canRead(do, "uid=anybody,DC=example,DC=com")
#' do <- setPublicAccess(do)
#' canRead(do, "public")
#' canRead(do, "uid=anybody,DC=example,DC=com")
#' # Also can create using a file for storage, rather than memory
#' \dontrun{
#' tf <- tempfile()
#' con <- file(tf, "wb")
#' writeBin(data, con)
#' close(con)
#' targetPath <- "myData/time-trials/trial_data.csv"
#' do <- new("DataObject", "id1", format="text/csv", user="uid=jones,DC=example,DC=com", 
#'   mnNodeId="urn:node:KNB", filename=tf, targetPath=targetPath)
#' }
#' @export
setClass("DataObject", slots = c(
    sysmeta                 = "SystemMetadata",
    data                    = "raw",
    filename                = "character",
    dataURL                 = "character",
    updated                 = "list",
    oldId                   = "character",
    targetPath              = "character")
)

##########################
## DataObject constructors
##########################

#' Initialize a DataObject
#' @rdname DataObject-initialize
#' @aliases DataObject-initialize
#' @description When initializing a DataObject using passed in data, one can either pass 
#' in the \code{'id'} param as a \code{'SystemMetadata'} object, or as a \code{'character'} string 
#' representing the identifier for an object along with parameters for format, user,and associated member node.
#' If \code{'data'} is not missing, the \code{'data'} param holds the \code{'raw'} data.  Otherwise, the
#' \code{'filename'} parameter must be provided, and points at a file containing the bytes of the data.
#' @details If filesystem storage is used for the data associated with a DataObject, care must be
#' taken to not modify or remove that file in R or via other facilities while the DataObject exists in the R session.
#' Changes to the object are not detected and will result in unexpected results. Also, if the \code{'dataobj'} parameter
#' is used to specify the data source, then \code{'filename'} argument may also be specified, but in this case 
#' the value \code{'filename'} parameter is used to tell DataONE the filename to create when this file is
#' downloaded from a repository.
#' @param .Object the DataObject instance to be initialized
#' @param id the identifier for the DataObject, unique within its repository. Optionally this can be an existing SystemMetadata object
#' @param dataobj the bytes of the data for this object in \code{'raw'} format, optional if \code{'filename'} is provided
#' @param format the format identifier for the object, e.g."text/csv", "eml://ecoinformatics.org/eml-2.1.1"
#' @param user the identity of the user owning the package, typically in X.509 format
#' @param mnNodeId the node identifier for the repository to which this object belongs.
#' @param filename the filename for the fully qualified path to the data on disk, optional if \code{'data'} is provided
#' @param seriesId A unique string to identifier the latest of multiple revisions of the object.
#' @param mediaType The When specified, indicates the IANA Media Type (aka MIME-Type) of the object. The value should include the media type and subtype (e.g. text/csv).
#' @param mediaTypeProperty A list, indicates IANA Media Type properties to be associated with the parameter \code{"mediaType"}
#' @param dataURL A character string containing a URL to remote data (a repository) that this DataObject represents.
#' @param targetPath An optional string that denotes where the file should go in a downloaded package
#' @param checksumAlgorithm A character string specifying the checksum algorithm to use
#' @import digest
#' @import uuid
#' @examples
#' data <- charToRaw("1,2,3\n4,5,6\n")
#' do <- new("DataObject", "id1", dataobj=data, "text/csv", 
#'   "uid=jones,DC=example,DC=com", "urn:node:KNB", targetPath="data/rasters/data.tiff")
#' @seealso \code{\link{DataObject-class}}
setMethod("initialize", "DataObject", function(.Object, id=NA_character_, dataobj=NA, format=NA_character_, user=NA_character_, 
                                               mnNodeId=NA_character_, filename=NA_character_, seriesId=NA_character_,
                                               mediaType=NA_character_, mediaTypeProperty=list(), dataURL=NA_character_,
                                               targetPath=NA_character_, checksumAlgorithm="SHA-256") {
  
    # If no value has been passed in for 'id', then create a UUID for it.
    if (!inherits(id, "SystemMetadata") && is.na(id)) {
        id <- paste0("urn:uuid:", UUIDgenerate())
    }
    
    # Params specified 
    # dataUrl filename dataobj comment
    # ------- -------- ------- -------
    # Y       N        N       used for lazy loaded DataObjects, 'dataUrl' is the data source
    # N       Y        Y       'dataobj' is the data source, 'filename' is sysmeta.filename (download filename)
    # N       Y        N       'filename' is the data source, 'filename' is sysmeta.filename
    # N       N        Y       Invalid, if 'dataobj' is specified, 'filename' must also be specified.
    # 
    hasDataUrl <- !is.na(dataURL)
    hasDataObj <- !is.na(dataobj[[1]])
    hasFilename <- !is.na(filename)
    
    if (!hasDataUrl && !hasDataObj && !hasFilename) {
        stop("Either the \"dataobj\" parameter containing raw data or the \"filename\" parameter with a file reference to the data\n or the \"xdataURL\" parameter must be provided.")
    }
    
    if (typeof(id) == "character") {
        smfile <- NA_character_
        size <- 0
        sha256 <- NA_character_
        dmsg("@@ DataObject-class:R initialize as character")
        if(hasDataUrl) {
            .Object@dataURL <- dataURL
            .Object@data <- as.raw(NULL)
            .Object@filename <- NA_character_
            smfile <- basename(dataURL) 
        } else {
            # Validate: dataobj must be raw if provided. Also, the filename argument must be provided, which will
            # be used as the sysmeta.fileName value.
            if (hasDataObj) {
                if(!is.raw(dataobj[[1]])) stop("The value of the \"dataobj\" parameter must be of type \"raw\"")
                smfile <- NA_character_
                # If dataobj is specified, then file at 'filename' location doesn't have to exist, as in this case 'filename'
                # specifies sysmeta.fileName and not the data source.
                if(!hasFilename) {
                #    warning("If the \"dataobj\" parameter is specified, the \"filename\" parameter must also be, to specify the download filename")
                    smfile <- basename(filename)
                }
                size <- length(dataobj)
                .Object@data <- dataobj
                .Object@filename <- NA_character_
                .Object@dataURL <- NA_character_
            } else {
                if(!file.exists(filename)) stop(sprintf("The \"filename\" argument value \"%s\" must be for file that exists", filename))
                fileinfo <- file.info(filename)
                if(!fileinfo$size > 0) stop(sprintf("The \"filename\" argument value \"%s\" must be for a non-empty file.", filename))
                size <- fileinfo$size
                .Object@data <- as.raw(NULL)
                .Object@dataURL <- dataURL
                .Object@filename <- normalizePath(filename)
                smfile <- basename(filename)
            }
        } 
        
        checksum <- calculateChecksum(.Object, checksumAlgorithm=checksumAlgorithm)
        # Build a SystemMetadata object describing the data
        # It's OK to set sysmeta v2 fields here, as they will only get serialized to v2 format if requested. The default is
        # to serialze to v1 format which does not include seriesId, mediaType, fileName.
        .Object@sysmeta <- new("SystemMetadata", identifier=id, formatId=format, size=size, submitter=user, rightsHolder=user, 
                               checksum=checksum, checksumAlgorithm=checksumAlgorithm, originMemberNode=mnNodeId, authoritativeMemberNode=mnNodeId, 
                               seriesId=seriesId, mediaType=mediaType, fileName=basename(smfile), 
                               mediaTypeProperty=mediaTypeProperty)
    } else if (typeof(id) == "S4" && inherits(id, "SystemMetadata")) {
        .Object@sysmeta <- id
        if(hasDataObj) {
            if(!is.raw(dataobj[[1]])) stop("The value of the \"dataobj\" parameter must be of type \"raw\"")
            .Object@data <- dataobj
            .Object@dataURL <- NA_character_
        } else {
            .Object@data <- as.raw(NULL)
            .Object@dataURL <- NA_character_
        }
        if(hasFilename && file.exists(filename)) {
            .Object@filename <- normalizePath(filename)
            .Object@dataURL <- NA_character_
        } else {
            .Object@filename <- NA_character_
            .Object@dataURL <- NA_character_
        }
        
        # Ensure that the checksum and algorithm of the passed in sysmeta matches the requested
        # values from the parameter list for the DataObject
        if(tolower(id@checksumAlgorithm) != tolower(checksumAlgorithm)) {
            checksum <- calculateChecksum(.Object, checksumAlgorithm=checksumAlgorithm)
            .Object@sysmeta@checksum <- checksum
            .Object@sysmeta@checksumAlgorithm <- checksumAlgorithm
        }
    } else {
        stop("Invalid value for \"identifier\" argument, it must be a character or SystemMetadata value\n")
    }

    # Test if this DataObject is brand new, or possibly created from an existing object, i.e.
    # downloaded from a data repository
    .Object@updated <- list("sysmeta" = FALSE, "data" = FALSE)
    .Object@oldId <- NA_character_
    if (!is.na(targetPath)) {
        targetPath <- pathToPOSIX(targetPath)
    }

    .Object@targetPath <- targetPath
    return(.Object)
})

#' Get the data content of a specified data object
#' 
#' @param x  DataObject or DataPackage: the data structure from where to get the data
#' @param ... Additional arguments
#' @aliases getData
#' @seealso \code{\link{DataObject-class}}
#' @export
setGeneric("getData", function(x, ...) {
    standardGeneric("getData")
})

#' @rdname getData
#' @return raw representation of the data
#' @aliases getData
#' @examples
#' data <- charToRaw("1,2,3\n4,5,6\n")
#' do <- new("DataObject", "id1", dataobj=data, "text/csv", 
#'   "uid=jones,DC=example,DC=com", "urn:node:KNB")
#' bytes <- getData(do)
setMethod("getData", signature("DataObject"), function(x) {
  if (length(x@data) > 0) {
    return(x@data)
  } else if(!is.na(x@filename)) {
    # Read the file from disk and return the contents as raw
    stopifnot(!is.na(x@filename))
    fileinfo <- file.info(x@filename)
    con <- file(x@filename, "rb")
    temp <- readBin(con, raw(), x@sysmeta@size)
    close(con)
    return(temp)
  } else if (!is.na(x@dataURL)) {
    # This DataObject was created by downloading an object from
    # a repository, but the size of the object to downlaod was too
    # large, so downloading the data was deferred. Now the user is
    # trying to get the data, so we have to download the data, regardless
    # of size.
    # TODO: this request may fail if the data isn't publicly readable, as this isn't
    # request doesn't use the dataone authorized request, i.e. dataone::getObject
    if(requireNamespace("httr", quietly=TRUE)) {
      #if(!is.element("package:httr", search())) env <- attachNamespace("httr")
      response <- httr::GET(x@dataURL)
      if (response$status != "200") {
        errorMsg <- httr::http_status(response)$message
        stop(sprintf("getData() error: %s\n", errorMsg))
      }
      # Can't set a slot in the DataObject to hold the data, as we
      # are returning data and not the modified DataObject
      data <- httr::content(response, as = "raw")
      return(data)
    } else {
        msg <- sprintf("Unable to get package member data from remote location: %s", x@dataURL)
        msg <- sprintf("%s\nInstalling package \"httr\" is required for this operation", msg)
        stop(msg)
    }
  }
})

#' Get the Identifier of the DataObject
#' @param x DataObject
#' @param ... (not yet used)
#' @return the identifier
#' @aliases getIdentifier
#' @seealso \code{\link{DataObject-class}}
#' @export
setGeneric("getIdentifier", function(x, ...) {
    standardGeneric("getIdentifier")
})

#' @rdname getIdentifier
#' @aliases getIdentifier
#' @examples 
#' data <- charToRaw("1,2,3\n4,5,6\n")
#' do <- new("DataObject", "id1", dataobj=data, "text/csv", 
#'   "uid=jones,DC=example,DC=com", "urn:node:KNB")
#' id <- getIdentifier(do)
setMethod("getIdentifier", signature("DataObject"), function(x) {
	return(x@sysmeta@identifier)
})

#' Get the FormatId of the DataObject
#' @param x DataObject
#' @param ... (not yet used)
#' @return the formatId
#' @aliases getFormatId
#' @seealso \code{\link{DataObject-class}}
#' @export
setGeneric("getFormatId", function(x, ...) {
			standardGeneric("getFormatId")
})

#' @rdname getFormatId
#' @aliases getFormatId
#' @examples
#' data <- charToRaw("1,2,3\n4,5,6\n")
#' do <- new("DataObject", "id1", dataobj=data, "text/csv", 
#'   "uid=jones,DC=example,DC=com", "urn:node:KNB")
#' fmtId <- getFormatId(do)
setMethod("getFormatId", signature("DataObject"), function(x) {
    return(x@sysmeta@formatId)
})

#
#' @rdname hasAccessRule
#' @description If called for a DataObject, then the SystemMetadata for the DataObject is checked.
#' @seealso \code{\link{DataObject-class}}
#' @examples 
#' #
#' # Check access rules for a DataObject
#' data <- system.file("extdata/sample-data.csv", package="datapack")
#' do <- new("DataObject", file=system.file("./extdata/sample-data.csv", package="datapack"), 
#'                                          format="text/csv")
#' do <- setPublicAccess(do)
#' isPublic <- hasAccessRule(do, "public", "read")
#' accessRules <- data.frame(subject=c("uid=smith,ou=Account,dc=example,dc=com", 
#'                           "uid=wiggens,o=unaffiliated,dc=example,dc=org"), 
#'                           permission=c("write", "changePermission"), 
#'                           stringsAsFactors=FALSE)
#' do <- addAccessRule(do, accessRules)
#' SmithHasWrite <- hasAccessRule(do, "uid=smith,ou=Account,dc=example,dc=com", "write")
#' @return When called for a DataObject, boolean TRUE if the access rule exists already, FALSE otherwise
setMethod("hasAccessRule", signature("DataObject"), function(x, subject, permission) {
    found <- hasAccessRule(x@sysmeta, subject, permission)
    return(found)
})

#' @rdname removeAccessRule
#' @return The DataObject object with the updated access policy.
#' @seealso \code{\link{DataObject-class}}
#' @examples 
#' #
#' # Remove access rules form a DataObject.
#' library(datapack)
#' do <- new("DataObject", file=system.file("./extdata/sample-data.csv", package="datapack"), 
#'                         format="text/csv")
#' do <- setPublicAccess(do)
#' isPublic <- hasAccessRule(do, "public", "read")
#' accessRules <- data.frame(subject=c("uid=smith,ou=Account,dc=example,dc=com", 
#'                           "uid=wiggens,o=unaffiliated,dc=example,dc=org"), 
#'                           permission=c("write", "changePermission"), 
#'                           stringsAsFactors=FALSE)
#' do <- addAccessRule(do, accessRules)
#' do <- removeAccessRule(do, "uid=smith,ou=Account,dc=example,dc=com", "changePermission")
#' # hasAccessRule should return FALSE
#' hasWrite <- hasAccessRule(do, "smith", "write")
#' 
#' # Alternatively, parameter "y" can be a data.frame containing one or more access rules:
#' do <- addAccessRule(do, "uid=smith,ou=Account,dc=example,dc=com", "write")
#' accessRules <- data.frame(subject=c("uid=smith,ou=Account,dc=example,dc=com", 
#'   "uid=slaughter,o=unaffiliated,dc=example,dc=org"), 
#'   permission=c("write", "changePermission"))
#' sysmeta <- removeAccessRule(do, accessRules)
#' @export
setMethod("removeAccessRule", signature("DataObject"), function(x, y, ...) {
    x@sysmeta <- removeAccessRule(x@sysmeta, y, ...)
    return(x)
})

#' Add a Rule to the AccessPolicy to make the object publicly readable.
#' 
#' To be called prior to creating the object in DataONE.  When called before 
#' creating the object, adds a rule to the access policy that makes this object
#' publicly readable.  If called after creation, it will only change the system
#' metadata locally, and will not have any effect on remotely uploaded copies of
#' the DataObject. 
#' @param x DataObject
#' @param ... (not yet used)
#' @return A DataObject with modified access rules.
#' @aliases setPublicAccess
#' @seealso \code{\link{DataObject-class}}
#' @export
setGeneric("setPublicAccess", function(x, ...) {
  standardGeneric("setPublicAccess")
})

#' @rdname setPublicAccess
#' @aliases setPublicAccess
#' @seealso \code{\link{DataObject-class}}
#' @examples
#' data <- charToRaw("1,2,3\n4,5,6\n")
#' do <- new("DataObject", "id1", dataobj=data, "text/csv", 
#'   "uid=jones,DC=example,DC=com", "urn:node:KNB")
#' do <- setPublicAccess(do)
setMethod("setPublicAccess", signature("DataObject"), function(x) {
    # Check if public: read is already set, and if not, set it
    if (!hasAccessRule(x@sysmeta, "public", "read")) {
        x@sysmeta <- addAccessRule(x@sysmeta, "public", "read")
    }
    return(x)
})

#' @rdname addAccessRule
#' @return The DataObject with the updated access policy
#' @seealso \code{\link{DataObject-class}}
#' @examples 
#' # Add an access rule to a DataObject
#' data <- charToRaw("1,2,3\n4,5,6\n")
#' obj <- new("DataObject", id="1234", dataobj=data, format="text/csv")
#' obj <- addAccessRule(obj, "uid=smith,ou=Account,dc=example,dc=com", "write")
setMethod("addAccessRule", signature("DataObject"), function(x, y, ...) {
    x@sysmeta <- addAccessRule(x@sysmeta, y, ...)
  return(x)
})

#' @rdname clearAccessPolicy
#' @return The DataObject with the cleared access policy.
#' @seealso \code{\link{DataObject-class}}
#' @examples 
#' # Clear access policy for a DataObject
#' do <- new("DataObject", format="text/csv", filename=system.file("extdata/sample-data.csv", 
#'           package="datapack"))
#' do <- addAccessRule(do, "uid=smith,ou=Account,dc=example,dc=com", "write")
#' do <- clearAccessPolicy(do)
#' @export
setMethod("clearAccessPolicy", signature("DataObject"), function(x, ...) {
        
    x@sysmeta <- clearAccessPolicy(x@sysmeta)
    
    return(x)
})

#' Test whether the provided subject can read an object.
#' 
#' Using the AccessPolicy, tests whether the subject has read permission
#' for the object.  This method is meant work prior to submission to a repository, 
#' and will show the permissions that would be enforced by the repository on submission.
#' Currently it only uses the AccessPolicy to determine who can read (and not the rightsHolder field,
#' which always can read an object).  If an object has been granted read access by the
#' special "public" subject, then all subjects have read access.
#' @details The subject name used in both the AccessPolicy and in the \code{'subject'}
#' argument to this method is a string value, but is generally formatted as an X.509
#' name formatted according to RFC 2253.
#' @param x DataObject
#' @param ... Additional arguments
#' @return boolean TRUE if the subject has read permission, or FALSE otherwise
#' @aliases canRead
#' @seealso \code{\link{DataObject-class}}
#' @export
setGeneric("canRead", function(x, ...) {
  standardGeneric("canRead")
})

#' @rdname canRead
#' @param subject : the subject name of the person/system to check for read permissions
#' @export
#' @examples 
#' data <- charToRaw("1,2,3\n4,5,6\n")
#' obj <- new("DataObject", id="1234", dataobj=data, format="text/csv")
#' obj <- addAccessRule(obj, "smith", "read")
#' access <- canRead(obj, "smith")
setMethod("canRead", signature("DataObject"), function(x, subject) {

    canRead <- hasAccessRule(x@sysmeta, "public", "read") | hasAccessRule(x@sysmeta, subject, "read")
	return(canRead)
})

#' Update selected elements of the XML content of a DataObject
#' @description The data content of the DataObject is updated by using the \code{xpath} 
#' argument to locate the elements to update with the character value specified in the 
#' \code{replacement} argument.
#' @param x A DataObject instance
#' @param ... Additional parameters (not yet used)
#' @return The modified DataObject
#' @rdname updateXML
#' @import XML
#' @export
#' @examples \dontrun{
#' library(datapack)
#' dataObj <- new("DataObject", format="text/csv", file=sampleData)
#' sampleEML <- system.file("extdata/sample-eml.xml", package="datapack")
#' dataObj <- updateMetadata(dataObj, xpath="", replacement=)
#' }
#' @seealso \code{\link{DataObject-class}}
setGeneric("updateXML", function(x, ...) {
    standardGeneric("updateXML")
})

#' @rdname updateXML
#' @param xpath A \code{character} value specifying the location in the XML to update.
#' @param replacement A \code{character} value that will replace the elements found with the \code{xpath}.
#' @export
#' @examples 
#' library(datapack)
#' # Create the metadata object with a sample EML file
#' sampleMeta <- system.file("./extdata/sample-eml.xml", package="datapack")
#' metaObj <- new("DataObject", format="eml://ecoinformatics.org/eml-2.1.1", file=sampleMeta)
#' # In the metadata object, replace "sample-data.csv" with 'sample-data.csv.zip'
#' xp <- sprintf("//dataTable/physical/objectName[text()=\"%s\"]", "sample-data.csv")
#' metaObj <- updateXML(metaObj, xpath=xp, replacement="sample-data.csv.zip")
setMethod("updateXML", signature("DataObject"), function(x, xpath=NA_character_, replacement=NA_character_, ...) {
    
    filename <- NA_character_
    filepath <- NA_character_
    metadataDoc <- NA_character_
    nodeSet <- list()
    
    # Use the existing checksum algorithm for the new (replaced) DataObject content
    checksumAlgorithm <- x@sysmeta@checksumAlgorithm
    
    # Get the xml content and update it if the xpath is found
    # Check that the parsing didn't generate an error
    result = tryCatch ({
        metadataDoc = xmlInternalTreeParse(rawToChar(getData(x)))
        nodeSet = xpathApply(metadataDoc,xpath)
    }, warning = function(warningCond) {
        cat(sprintf("Warning: %s\n", warningCond$message))
    }, error = function(errorCond) {
        cat(sprintf("Error: %s\n", errorCond$message))
    }, finally = {
        if(length(nodeSet) == 0) {
            stop(sprintf("No elements found in XML of DataObject with id: %s using xpath: %s", 
                         getIdentifier(x), xpath))
        }
    })
    
    # Substitute the new value(s) into the document
    sapply(nodeSet,function(node){
        xmlValue(node) = replacement
    })
    
    newfile <- tempfile(pattern="metadata", fileext=".xml")
    saveXML(metadataDoc, file=newfile)
    # xml2 version of updating XML
    #metadataDoc <- read_xml(getData(x), encoding = "", as_html = FALSE, options = "NOBLANKS")
    #node <- xml_find_first(metadataDoc,  xpath=xpath, ns = xml_ns(metadataDoc))
    #xml_text(node) <- replacement
    #write_xml(metadataDoc, filepath)
    
    # See how the data was stored in the previous version of the DataObject and
    # create the new, replacement DataObject using the same method (i.e. either internal data or external file)
    if (length(x@data) > 0) {
        metadata <- readChar(newfile, file.info(newfile)$size)
        x@data <- charToRaw(metadata)
        x@filename <- NA_character_
        x@sysmeta@size <- length(x@data)
        x@sysmeta@checksum <- calculateChecksum(x, checksumAlgorithm=checksumAlgorithm)
    } else {
        # Read the file from disk and return the contents as raw
        x@data <- raw()
        x@filename <- newfile
        fileinfo <- file.info(newfile)
        x@sysmeta@size <- fileinfo$size
        x@sysmeta@checksum <- calculateChecksum(x, checksumAlgorithm=checksumAlgorithm)
    }
    
    return(x)
})

setMethod("show", "DataObject",
          #function(object)print(rbind(x = object@x, y=object@y))
          function(object) {
              consoleWidth <- getOption("width")
              if(is.na(consoleWidth)) consoleWidth <- 80
              nameWidth <- 25
              valueWidth <- 30
              colWidth <- as.integer((consoleWidth - 5)/2)
              
              fmt <- paste0("%-", sprintf("%2d", nameWidth), "s ", ": ",
                           "%-", sprintf("%2d", valueWidth), "s ",
                           "\n")
              fmt2 <- paste0("%-", sprintf("%2d", colWidth), "s ",
                           "%-", sprintf("%2d", colWidth), "s ",
                           "\n")
              
              cat(sprintf("Access\n"))
              cat(sprintf(fmt, "  identifer", object@sysmeta@identifier))
              cat(sprintf(fmt, "  submitter", object@sysmeta@submitter))
              cat(sprintf(fmt, "  rightHolder", object@sysmeta@rightsHolder))
              cat(sprintf("  access policy:\n"))
              if(nrow(object@sysmeta@accessPolicy) > 0) {
                  cat(sprintf(fmt2, "    subject", "permission"))
                  for(irow in seq_len(nrow(object@sysmeta@accessPolicy))) {
                      subject <- object@sysmeta@accessPolicy[irow, 'subject']
                      permission <- object@sysmeta@accessPolicy[irow, 'permission']
                      cat(sprintf(fmt2, condenseStr(paste0("    ", subject), colWidth), permission))
                  }
              } else {
                 cat(sprintf("\t\tNo access policy defined\n")) 
              }
              cat(sprintf("Physical\n"))
              cat(sprintf(fmt, "  formatId", object@sysmeta@formatId))
              cat(sprintf(fmt, "  mediaType", object@sysmeta@mediaType))
              cat(sprintf(fmt, "  mediaTypeProperty", object@sysmeta@mediaTypeProperty))
              cat(sprintf(fmt, "  size", object@sysmeta@size))
              cat(sprintf("System\n"))
              cat(sprintf(fmt, "  seriesId", object@sysmeta@seriesId))
              cat(sprintf(fmt, "  serialVersion", object@sysmeta@serialVersion))
              cat(sprintf(fmt, "  obsoletes", object@sysmeta@obsoletes))
              cat(sprintf(fmt, "  obsoletedBy", object@sysmeta@obsoletedBy))
              cat(sprintf(fmt, "  archived", object@sysmeta@archived))
              cat(sprintf(fmt, "  dateUploaded", object@sysmeta@dateUploaded))
              cat(sprintf(fmt, "  dateSysMetadataModified", object@sysmeta@dateSysMetadataModified))
              cat(sprintf("Data\n"))
              if(!is.na(object@filename)) {
                cat(sprintf(fmt, "  filename", object@filename))
              } else {
                cat("  ", class(object@data), ": ", utils::head(object@data), " ...\n")
              }
          }
)

# Returns a path in the form of the native OS. When run
# on Windows, a Windows compliant path is returned. When run on
# PSOIX, a POSIX compliant path is returned.
getPlatformPath <- function(filePath) {
    if(.Platform$OS.type == "windows") {
        filePath <- pathToWindows(filePath)
    } else {
        filePath <-pathToPOSIX(filePath)
    }
    return(filePath)
}

# Turns a path into a POSIX compliant path
pathToPOSIX <- function(filePath) {
    filePath <- gsub('\\\\', '/', filePath)
    filterList <- list( '$', '?', '|', '"', '<', '>', '..')
    pathInformation <- sanitizePath(filePath, filterList)
    # Replace any windows-style paths
    return(file.path(pathInformation[1], pathInformation[2]))
}

# Turns a path into a Windows compliant path
pathToWindows<- function(filePath) {
    # List of things that shouldn't be in a path
    filterList <- list( '?', '*', '|', '"', '<', '>', '..')
    pathInformation <- sanitizePath(filePath, filterList)
    return(file.path(pathInformation[1], pathInformation[2]))
}

# Takes a path and a list of characters that should be removed
# and returns the path without the characters. It also sanitizes the
# file name .
sanitizePath <- function(filePath, filterList) {
    filename <- basename(filePath)
    path = dirname(filePath)
    
    filename <- fs::path_sanitize(filename, "")
    
    # List of things that shouldn't be in a path
    for (filterCharacter in filterList) {
        path <- gsub(filterCharacter, '_', path, fixed=TRUE)
    }
    return(c(path, filename))
}

# DataONE uses different abbreviations for checksum algorithms than the R 'digest' function.
# Given a DataONE checksum algorithm abbreviation, return the corresponding 'digest' abbreviation,
# which is needed in the 'digest' function call.
getChecksumAlgorithmAbbreviation <- function(checksumAlgorithm="SHA-256") {
    
    # DataONE and the R 'digest' package have different abbreviations for checksum algorithm designations.
    # Take a DataONE abbreviation and return the corresponding R 'digest' abbreviation
    
    if (tolower(checksumAlgorithm) == "md5") {
        abbr="md5"
    }
    else if (tolower(checksumAlgorithm) == "sha1") {
        abbr="sha1"
    }
    else if (tolower(checksumAlgorithm) == "sha-1") {
        abbr="sha1"
    }
    else if (tolower(checksumAlgorithm) == "sha256") {
        abbr="sha256"
    }
    else if (tolower(checksumAlgorithm) == "sha-256") {
        abbr="sha256"
    } else {
        warning(sprintf("Unknown checksum algorithm %s", checksumAlgorithm))
    }
    
    return(abbr) 
}

#' Calculate a checksum for the DataObject using the specified checksum algorithm
#' @description calculates a checksum
#' @param x A DataObject instance
#' @param ... Additional parameters (not yet used)
#' @note this method is intended for internal package use only.
#' @return The calculated checksum
setGeneric("calculateChecksum", function(x, ...) {
    standardGeneric("calculateChecksum")
})

#' @rdname calculateChecksum
#' @param checksumAlgorithm a \code{character} value specifying the checksum algorithm to use (i.e "MD5" or "SHA1" or "SHA256")
setMethod("calculateChecksum", signature("DataObject"), function(x, checksumAlgorithm="SHA256", ...) {
    abbr <- getChecksumAlgorithmAbbreviation(checksumAlgorithm)
    
    if(!is.na(x@dataURL)) {
        if (tolower(checksumAlgorithm) == x@sysmeta@checksumAlgorithm) {
            checksum <- x@sysmeta@checksum
        } else {
            warning("Unable to calculate checksum for DataObject without local content.")
        }
    } else if (length(x@data) > 0) {
        checksum <- digest(x@data, algo=abbr, serialize=FALSE, file=FALSE)
    } else if (!is.na(x@filename)) {
        checksum <- digest(x@filename, algo=abbr, serialize=FALSE, file=TRUE)
    } else {
        warning("DataObject does not contain data or a data URL.")
    }
    
    return(checksum)
    
})
          
