package test

import (
	"path/filepath"
	"strings"
	"testing"

	"github.com/microsoft/fabrikate/cmd"
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
	if err != nil {
		t.Error(err.Error())
	}

	for _, component := range components {
		err = cmd.Install(component)
		if err != nil {
			t.Error(err.Error())
		}
		_, err = cmd.Generate(component, []string{"common"}, false)
		if err != nil {
			t.Error(err.Error())
		}
	}
}
