import struct

class ScpEcg:
    def __init__(self, file_path):
        self.file_path = file_path
        self.header = None
        self.patient_info = None
        self.ecg_data = None
        self.diagnose_info = None

    def read(self):
        try:
            with open(self.file_path, 'rb') as f:
                # Example: Reading the first 20 bytes for the header (assuming the header is 20 bytes)
                header_data = f.read(20)
                self.header = struct.unpack('<20s', header_data)
                print("Header:", self.header)

                # Assuming patient info is the next 100 bytes (this is an example; adjust based on specification)
                patient_info_data = f.read(100)
                self.patient_info = struct.unpack('<100s', patient_info_data)
                print("Patient Info:", self.patient_info)

                # Example of reading ECG data (you would need the correct format based on SCP-ECG specification)
                ecg_data_length = 500  # Example length of ECG data
                ecg_data = f.read(ecg_data_length)
                self.ecg_data = struct.unpack(f'<{ecg_data_length}s', ecg_data)
                print("ECG Data:", self.ecg_data)

                # Assuming diagnostic info follows ECG data
                diagnose_info_data = f.read(200)  # Example length of diagnostic data
                self.diagnose_info = struct.unpack('<200s', diagnose_info_data)
                print("Diagnostic Info:", self.diagnose_info)

                # You would continue reading and unpacking other parts of the file as needed
        except Exception as e:
            print(f"Error reading SCP-ECG file: {e}")

    def display_info(self):
        print("\n--- SCP-ECG File Information ---")
        print("Header:", self.header)
        print("Patient Info:", self.patient_info)
        print("ECG Data:", self.ecg_data)
        print("Diagnostic Info:", self.diagnose_info)


def usage_example():
    path = "rest.scp"  # Replace with the path to your SCP-ECG file
    scp_ecg = ScpEcg(path)
    scp_ecg.read()
    scp_ecg.display_info()

# Run the usage example
if __name__ == "__main__":
    usage_example()
