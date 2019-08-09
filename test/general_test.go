package test

import (
	"os"
	"path"
	"path/filepath"
	"strings"
	"testing"

	"github.com/microsoft/fabrikate/cmd"
	"github.com/stretchr/testify/assert"
)

func getAllComponentDirectories() ([]string, error) {
	componentDirectories := []string{}
	extensions := []string{"yaml", "yml", "json"}

	for _, ext := range extensions {
		componentPath := strings.Join([]string{"../definitions/*/component.", ext}, "")
		componentFiles, err := filepath.Glob(componentPath)
		if err != nil {
			return nil, err
		}

		for _, component := range componentFiles {
			parentDir := filepath.Dir(component)
			absoluteParentPath, err := filepath.Abs(parentDir)
			if err != nil {
				return nil, err
			}
			componentDirectories = append(componentDirectories, absoluteParentPath)
		}
	}

	return componentDirectories, nil
}

// Test that all components in /definitions can be Install and Generate correctly
func TestInstallAndGenerate(t *testing.T) {
	components, err := getAllComponentDirectories()
	assert.Nil(t, err)

	for _, component := range components {
		t.Logf("Starting tests on %s", component)
		// Clean: Must clean files from ALL components in this repository for every install/generate as previous installs can break new install
		for _, dir := range []string{"helm_repos", "components", "generated"} {
			for _, componentDirToClean := range components {
				err = os.RemoveAll(path.Join(componentDirToClean, dir))
				assert.Nil(t, err)
			}
		}

		// Install
		err = cmd.Install(component)
		assert.Nil(t, err)

		// Generate
		_, err = cmd.Generate(component, []string{"common"}, false)
		assert.Nil(t, err)
		t.Logf("Completed tests on %s", component)
	}
}
