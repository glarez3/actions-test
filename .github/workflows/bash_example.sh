#!/usr/bin/bash

        PACKAGE_VERSION=${{ inputs.PACKAGE_VERSION }}
        PACKAGE_NAME=${{ inputs.PACKAGE_NAME }}
        PACKAGES_RESULT=$(aws codeartifact list-packages --domain cs-python-packages --domain-owner 153576335202 --repository ${{ inputs.CODE_ARTIFACT_REPOSITORY }} --format pypi)
        echo $PACKAGES_RESULT
        PACKAGES=$(echo $PACKAGES_RESULT | jq '.packages[]' | sed 's/"//g')
        # Check if the codeartifact repository is empty. If it's empty, upload the package directly
        if [ -z "$PACKAGES" ]; then
          echo "No package exists in the codeartifact repository."
          aws codeartifact login --tool twine --repository ${{ inputs.CODE_ARTIFACT_REPOSITORY }} --domain cs-python-packages --domain-owner 153576335202
          python setup.py sdist bdist_wheel
          twine upload --verbose --repository codeartifact dist/*
          exit 0
        #If the codeartifact repo is not empty, check if there is multiple pages of packages.
        else
          if [ "$(echo $PACKAGES_RESULT | jq 'has("nextToken")')" == false ]; then
            PACKAGE=$(echo $PACKAGES_RESULT | jq '.packages[] | select(.package == "'$PACKAGE_NAME'") | .package' | sed 's/"//g')
            # Check if the package and its version already exist in the single page payload of packages
            if [[ $PACKAGE == $PACKAGE_NAME ]]; then
              PACKAGE_VERSIONS=$(aws codeartifact list-package-versions --package ${{ inputs.PACKAGE_NAME }} --domain cs-python-packages --repository ${{ inputs.CODE_ARTIFACT_REPOSITORY }} --format pypi)
              VERSION=$(echo $PACKAGE_VERSIONS | jq '.versions[] | select(.version == "'$PACKAGE_VERSION'") | .version' | sed 's/"//g')
              if [[ $VERSION == $PACKAGE_VERSION ]]; then
                echo "The version, $PACKAGE_VERSION, already exists. Please update your package version before publishing."
                 exit 1
              else
                aws codeartifact login --tool twine --repository ${{ inputs.CODE_ARTIFACT_REPOSITORY }} --domain cs-python-packages --domain-owner 153576335202
                python setup.py sdist bdist_wheel
                twine upload --verbose --repository codeartifact dist/*
                exit 0
              fi
            else
              echo "uploading $PACKAGE_NAME"
              aws codeartifact login --tool twine --repository ${{ inputs.CODE_ARTIFACT_REPOSITORY }} --domain cs-python-packages --domain-owner 153576335202
              python setup.py sdist bdist_wheel
              twine upload --verbose --repository codeartifact dist/*
              exit 0
            fi
          
          # If there are multiple pages of packages, loop through all packages to check if the package and its version already exist
          else
            NEXT_TOKEN=$(echo $PACKAGES_RESULT | jq '.nextToken' | sed 's/"//g')
            PACKAGE=$(echo $PACKAGES_RESULT | jq '.packages[] | select(.package == "'$PACKAGE_NAME'") | .package' | sed 's/"//g')
            echo $PACKAGE
            if [[ $PACKAGE == $PACKAGE_NAME ]]; then
              PACKAGE_VERSIONS=$(aws codeartifact list-package-versions --package ${{ inputs.PACKAGE_NAME }} --domain cs-python-packages --repository ${{ inputs.CODE_ARTIFACT_REPOSITORY }} --format pypi)
              VERSION=$(echo $PACKAGE_VERSIONS | jq '.versions[] | select(.version == "'$PACKAGE_VERSION'") | .version' | sed 's/"//g')
              if [[ $VERSION == $PACKAGE_VERSION ]]; then
                echo "The version, $PACKAGE_VERSION, already exists. Please update your package version before publishing."
                exit 1
              else
                aws codeartifact login --tool twine --repository ${{ inputs.CODE_ARTIFACT_REPOSITORY }} --domain cs-python-packages --domain-owner 153576335202
                python setup.py sdist bdist_wheel
                twine upload --verbose --repository codeartifact dist/*
                exit 0
              fi
            else
              while [ ! -z "$NEXT_TOKEN" ]
              do
                PACKAGES_RESULT=$(aws codeartifact list-packages --domain cs-python-packages --domain-owner 153576335202 --repository ${{ inputs.CODE_ARTIFACT_REPOSITORY }} --format pypi --next-token "$NEXT_TOKEN")
                PACKAGE=$(echo $PACKAGES_RESULT | jq '.packages[] | select(.package == "'$PACKAGE_NAME'") | .package' | sed 's/"//g')
                if [[ $PACKAGE == $PACKAGE_NAME ]]; then
                  PACKAGE_VERSIONS=$(aws codeartifact list-package-versions --package ${{ inputs.PACKAGE_NAME }} --domain cs-python-packages --repository ${{ inputs.CODE_ARTIFACT_REPOSITORY }} --format pypi)
                  VERSION=$(echo $PACKAGE_VERSIONS | jq '.versions[] | select(.version == "'$PACKAGE_VERSION'") | .version' | sed 's/"//g')
                  if [[ $VERSION == $PACKAGE_VERSION ]]; then
                    echo "The version, $PACKAGE_VERSION, already exists. Please update your package version before publishing."
                    exit 1
                  else
                    aws codeartifact login --tool twine --repository ${{ inputs.CODE_ARTIFACT_REPOSITORY }} --domain cs-python-packages --domain-owner 153576335202
                    python setup.py sdist bdist_wheel
                    twine upload --verbose --repository codeartifact dist/*
                    exit 0
                  fi
                else
                  aws codeartifact login --tool twine --repository ${{ inputs.CODE_ARTIFACT_REPOSITORY }} --domain cs-python-packages --domain-owner 153576335202
                  python setup.py sdist bdist_wheel
                  twine upload --verbose --repository codeartifact dist/*
                  exit 0
                fi
                NEXT_TOKEN=$(echo $PACKAGES_RESULT | jq '.nextToken' | sed 's/"//g')
              done
            fi
          fi
        fi