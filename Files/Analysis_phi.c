#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <math.h>  // Include math.h for rounding

#define MAX_LINE_LENGTH 1000

// Function to extract Ymax from the input file
double getYmax(const char* input_file) {
    FILE *file = fopen(input_file, "r");
    if (!file) {
        perror("Error opening input file");
        exit(EXIT_FAILURE);
    }

    char line[MAX_LINE_LENGTH];
    double Ymax = 0.0;

    // Read each line and look for the line containing "size"
    while (fgets(line, sizeof(line), file)) {
        if (strstr(line, "size")) {
            // Extract the Ymax value from the format "size 3_64_1200"
            if (sscanf(line, "size 3_%lf_", &Ymax) == 1) {
                break;  // Successfully extracted Ymax
            } else {
                fprintf(stderr, "Error: Could not parse Ymax from line: %s\n", line);
            }
        }
    }

    fclose(file);

    if (Ymax == 0.0) {
        fprintf(stderr, "Warning: Ymax was not found or is zero in the input file.\n");
    }

    return Ymax;
}

// Function to modify the phi file
void modify_phi_file(const char* phi_file, double Ymax) {
    FILE *file = fopen(phi_file, "r");
    if (!file) {
        perror("Error opening phi file");
        exit(EXIT_FAILURE);
    }

    // Temporary file to store modified data
    FILE *temp_file = fopen("temp_phi.gplt", "w");
    if (!temp_file) {
        perror("Error creating temporary file for phi");
        fclose(file);  // Close the original file before exiting
        exit(EXIT_FAILURE);
    }

    double x, y, z, phi;
    while (fscanf(file, "%lf %lf %lf %lf", &x, &y, &z, &phi) != EOF) {
        x = 3.0;  // Set X to 3
        y = round(Ymax / 2); // Set Y value to Ymax / 2 and round it to the nearest integer

        // Write modified data to the temporary file
        fprintf(temp_file, "%.0f %d %.0f %.6e\n", x, (int)y, z, phi);
    }

    fclose(file);
    fclose(temp_file);

    // Replace the original file with the modified one
    remove(phi_file);
    rename("temp_phi.gplt", phi_file);
}

// Function to modify the vel file
void modify_vel_file(const char* vel_file, double Ymax) {
    FILE *file = fopen(vel_file, "r");
    if (!file) {
        perror("Error opening vel file");
        exit(EXIT_FAILURE);
    }

    // Temporary file to store modified data
    FILE *temp_file = fopen("temp_vel.gplt", "w");
    if (!temp_file) {
        perror("Error creating temporary file for vel");
        fclose(file);  // Close the original file before exiting
        exit(EXIT_FAILURE);
    }

    double x, y, z, vx, vy, vz;
    while (fscanf(file, "%lf %lf %lf %lf %lf %lf", &x, &y, &z, &vx, &vy, &vz) != EOF) {
        x = 3.0;  // Set X to 3
        y = round(Ymax / 2); // Set Y value to Ymax / 2 and round it to the nearest integer

        // Write modified data to the temporary file
        fprintf(temp_file, "%.0f %d %.0f %.6e %.6e %.6e\n", x, (int)y, z, vx, vy, vz);
    }

    fclose(file);
    fclose(temp_file);

    // Replace the original file with the modified one
    remove(vel_file);
    rename("temp_vel.gplt", vel_file);
}

// Function to process all phi and vel files in the directory
void process_files(const char* input_filename) {
    DIR *dir;
    struct dirent *entry;
    double Ymax = getYmax(input_filename);

    if ((dir = opendir(".")) != NULL) {
        // Loop through all files in the directory
        while ((entry = readdir(dir)) != NULL) {
            // Check if the file name matches the pattern "phi-*.gplt"
            if (strstr(entry->d_name, "phi-") && strstr(entry->d_name, ".gplt")) {
                printf("Processing phi file: %s\n", entry->d_name);
                modify_phi_file(entry->d_name, Ymax);
            }
            // Check if the file name matches the pattern "vel-*.gplt"
            else if (strstr(entry->d_name, "vel-") && strstr(entry->d_name, ".gplt")) {
                printf("Processing vel file: %s\n", entry->d_name);
                modify_vel_file(entry->d_name, Ymax);
            }
        }
        closedir(dir);
    } else {
        perror("Could not open directory");
        exit(EXIT_FAILURE);
    }
}

int main() {
    const char *input_filename = "input";  // Input file containing Ymax value

    // Process all phi and vel files in the current directory
    process_files(input_filename);

    printf("All files processed successfully.\n");

    return 0;
}
