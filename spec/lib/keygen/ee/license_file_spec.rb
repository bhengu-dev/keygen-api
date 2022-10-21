# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

require_dependency Rails.root.join('lib', 'keygen')

describe Keygen::EE::LicenseFile do
  TEST_PUBLIC_KEY   = ['775e65407f3d86de55efbac47d1bbeab79768a21a406e39976606a704984e7d1'].pack('H*')
  TEST_LICENSE_KEY  = 'TEST-116A58-3F79F9-9F1982-9D63B1-V3'
  TEST_LICENSE_FILE = Base64.strict_encode64(
    file_fixture('valid.lic').read,
  )

  before do
    stub_const('Keygen::PUBLIC_KEY', TEST_PUBLIC_KEY)
  end

  after do
    described_class.reset!
  end

  context 'when using the default license file source' do
    context 'when a valid license file exists' do
      with_file path: described_class::DEFAULT_PATH, fixture: 'valid.lic' do
        context 'when a valid license key is used' do
          with_env KEYGEN_LICENSE_KEY: TEST_LICENSE_KEY do
            it 'should be a valid license file' do
              lic = described_class.current

              expect(lic.expired?).to be false
              expect(lic.valid?).to be true
            end

            it 'should raise if clock is tampered' do
              lic = described_class.current

              with_time lic.issued - 1.minute do
                expect(lic.tampered?).to be true
                expect { lic.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
              end
            end
          end
        end

        context 'when an invalid license key is used' do
          with_env KEYGEN_LICENSE_KEY: 'TEST-INVALID' do
            it 'should fail to load license file' do
              lic = described_class.current

              expect { lic.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
            end
          end
        end
      end
    end

    context 'when an expired license file exists' do
      with_file path: described_class::DEFAULT_PATH, fixture: 'expired.lic' do
        context 'when a valid license key is used' do
          with_env KEYGEN_LICENSE_KEY: TEST_LICENSE_KEY do
            it 'should not be a valid license file' do
              lic = described_class.current

              expect(lic.expired?).to be true
              expect(lic.valid?).to be false
            end
          end
        end
      end
    end

    context 'when a tampered license file exists' do
      with_file path: described_class::DEFAULT_PATH, fixture: 'tampered.lic' do
        context 'when a valid license key is used' do
          with_env KEYGEN_LICENSE_KEY: TEST_LICENSE_KEY do
            it 'should fail to load license file' do
              lic = described_class.current

              expect { lic.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
            end
          end
        end
      end
    end

    context 'when a license file does not exist' do
      it 'should fail to load license file' do
        lic = described_class.current

        expect { lic.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
      end
    end
  end

  context 'when using a custom license file path' do
    context 'when using a real relative path' do
      with_env KEYGEN_LICENSE_FILE_PATH: file_fixture('valid.lic').relative_path_from(Rails.root), KEYGEN_LICENSE_KEY: TEST_LICENSE_KEY do
        it 'should be a valid license file' do
          lic = described_class.current

          expect(lic.valid?).to be true
        end
      end
    end

    context 'when using a relative path' do
      with_file path: '.ee.lic', fixture: 'valid.lic' do
        with_env KEYGEN_LICENSE_FILE_PATH: '.ee.lic', KEYGEN_LICENSE_KEY: TEST_LICENSE_KEY do
          it 'should be a valid license file' do
            lic = described_class.current

            expect(lic.valid?).to be true
          end
        end
      end
    end

    context 'when using an absolute path' do
      with_file path: '/etc/licenses/ee.lic', fixture: 'valid.lic' do
        with_env KEYGEN_LICENSE_FILE_PATH: '/etc/licenses/ee.lic', KEYGEN_LICENSE_KEY: TEST_LICENSE_KEY do
          it 'should be a valid license file' do
            lic = described_class.current

            expect(lic.valid?).to be true
          end
        end
      end
    end

    context 'when using an invalid path' do
      with_env KEYGEN_LICENSE_FILE_PATH: '/dev/null', KEYGEN_LICENSE_KEY: TEST_LICENSE_KEY do
        it 'should fail to load license file' do
          lic = described_class.current

          expect { lic.valid? }.to raise_error Keygen::EE::InvalidLicenseFileError
        end
      end
    end
  end

  context 'when using an encoded license file' do
    with_env KEYGEN_LICENSE_FILE: TEST_LICENSE_FILE, KEYGEN_LICENSE_KEY: TEST_LICENSE_KEY do
      it 'should be a valid license file' do
        lic = described_class.current

        expect(lic.valid?).to be true
      end
    end
  end
end
