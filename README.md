# ImageOptimizer
.SYNOPSIS
Compress and optimize gif, png, and jpg images in a folder structure

.DESCRIPTION
Compress and optimize gif, png, and jpg images in a folder structureand maintain copies of the original and optimized files in a copied folder structure for easy restore.

.PARAMETER 
FolderPath
	The base folder path to search.
Silent
	Flag to turn user interaction off 

.EXAMPLE
PS>  .\imageOptimizer.ps1 -FolderPath 'C:\www\site1' -Silent
