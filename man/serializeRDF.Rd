% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ResourceMap.R
\name{serializeRDF}
\alias{serializeRDF}
\alias{serializeRDF,ResourceMap-method}
\title{Serialize a ResouceMap.}
\usage{
serializeRDF(x, ...)

\S4method{serializeRDF}{ResourceMap}(
  x,
  file,
  syntaxName = "rdfxml",
  mimeType = "application/rdf+xml",
  namespaces = data.frame(namespace = character(), prefix = character(),
    stringsAsFactors = FALSE),
  syntaxURI = NA_character_
)
}
\arguments{
\item{x}{a ResourceMap}

\item{...}{Additional parameters}

\item{file}{the file to which the ResourceMap will be serialized}

\item{syntaxName}{name of the syntax to use for serialization - default is "rdfxml"}

\item{mimeType}{the mimetype of the serialized output - the default is "application/rdf+xml"}

\item{namespaces}{a data frame containing one or more namespaces and their associated prefix}

\item{syntaxURI}{A URI of the serialized syntax}
}
\value{
status of the serialization (non)
}
\description{
The Redland RDF library is used to serialize the ResourceMap RDF model
to a file as RDF/XML.
}
\examples{
dp <- new("DataPackage")
data <- charToRaw("1,2,3\n4,5,6")
do1 <- new("DataObject", id="id1", data, format="text/csv")
do2 <- new("DataObject", id="id2", data, format="text/csv")
dp <- addMember(dp, do1)
dp <- addMember(dp, do2)
dp <- insertRelationship(dp, subjectID="id1", objectIDs="id2", 
  predicate="http://www.w3.org/ns/prov#wasDerivedFrom")
relations <- getRelationships(dp)
resmap <- new("ResourceMap")
resmap <- createFromTriples(resmap, relations, id="myuniqueid")
\dontrun{
tf <- tempfile(fileext=".xml")
serializeRDF(resmap, tf)
}
}
\seealso{
\code{\link{ResourceMap-class}}
}
