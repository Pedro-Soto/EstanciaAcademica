#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

int main() {
    DIR *dir;
    struct dirent *entry;
    char *pattern = "phi-";
    char filename[500];
    char mapFilename[500];

    dir = opendir(".");
    if (dir == NULL) {
        printf("Error opening directory\n");
        return 1;
    }

    const int ymax = EPAISSEUR;
    const int zmax = LONGUEUR;
    
    double b = I;
	  
    // Returns the centre of the canal
    double j_centre = (ymax / 2);
    
    // Returns maximum sinusoidal wall amplitude
    double a = J;
    
    // Defines a side wall function for each z value    
    while ((entry = readdir(dir)) != NULL) {
        if (strncmp(entry->d_name, pattern, strlen(pattern)) == 0 &&
            strlen(entry->d_name) > 4 &&
            strcmp(entry->d_name + strlen(entry->d_name) - 4, ".vtk") == 0) {

            snprintf(filename, sizeof(filename), "%s", entry->d_name);
            printf("Found file: %s\n", filename);

            // Create the map filename by replacing .vtk with _map.vtk
            snprintf(mapFilename, sizeof(mapFilename), "%.*s_map.vtk", (int)(strlen(entry->d_name) - 4), entry->d_name);

            FILE *file = fopen(filename, "r");
            if (file == NULL) {
                printf("Error opening file %s\n", filename);
                continue;
            }

            // Temporary file to store valid lines
            FILE *tempFile = fopen("temp.vtk", "w");
            if (tempFile == NULL) {
                printf("Error creating temporary file\n");
                fclose(file);
                continue;
            }

            // File to write the map data
            FILE *mapFile = fopen(mapFilename, "w");
            if (mapFile == NULL) {
                printf("Error creating map file %s\n", mapFilename);
                fclose(file);
                fclose(tempFile);
                continue;
            }

            // Read and process the contents of the .vtk file
            char line[256];
            while (fgets(line, sizeof(line), file)) {
                int x, y, z;
                float phi;
                // Parse the line into variables
                if (sscanf(line, "%d %d %d %f", &x, &y, &z, &phi) == 4) {
                    // Calculate the bounds
                    double wall_right = j_centre + (b / 2) + a * cos(2 * M_PI * z / zmax);
                    double wall_left = j_centre - (b / 2) - a * cos(2 * M_PI * z / zmax); 

                    // Check if y is within the bounds
                    if (y >= wall_left && y <= wall_right) {
                        // Write the valid line to the temporary file
                        fprintf(tempFile, "%s", line);
                        // Optionally write to the map file (you can customize what to write)
                        fprintf(mapFile, "%d %d %d %f\n", x, y, z, phi); // Write valid data to map file
                        fprintf(mapFile, "\n"); // Add an empty line after each entry
                    } else {
                        printf("Line discarded: %s", line);
                    }
                } else {
                    printf("Failed to parse line: %s", line);
                }
            }

            fclose(file);
            fclose(tempFile);
            fclose(mapFile);

            // Replace the original file with the temporary file
            remove(filename); // Remove the original file
            rename("temp.vtk", filename); // Rename temp file to original file name
        }
    }

    closedir(dir);
    return 0;
}
