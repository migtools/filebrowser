package cmd

import (
	"github.com/spf13/cobra"
)

func init() {
	configCmd.AddCommand(configSetCmd)
	addConfigFlags(configSetCmd.Flags())
}

var configSetCmd = &cobra.Command{
	Use:   "set",
	Short: "Updates the configuration",
	Long: `Updates the configuration. Set the flags for the options
you want to change. Other options will remain unchanged.`,
	Args: cobra.NoArgs,
	RunE: withStore(func(cmd *cobra.Command, _ []string, st *store) error {
		flags := cmd.Flags()

		// Read existing config
		set, err := st.Settings.Get()
		if err != nil {
			return err
		}

		ser, err := st.Settings.GetServer()
		if err != nil {
			return err
		}

		hasAuth := false
		flags.Visit(func(flag *pflag.Flag) {
			if err != nil {
				return
			}
			switch flag.Name {
			case "baseurl":
				ser.BaseURL, err = getString(flags, flag.Name)
			case "root":
				ser.Root, err = getString(flags, flag.Name)
			case "socket":
				ser.Socket, err = getString(flags, flag.Name)
			case "cert":
				ser.TLSCert, err = getString(flags, flag.Name)
			case "key":
				ser.TLSKey, err = getString(flags, flag.Name)
			case "address":
				ser.Address, err = getString(flags, flag.Name)
			case "port":
				ser.Port, err = getString(flags, flag.Name)
			case "log":
				ser.Log, err = getString(flags, flag.Name)
			case "signup":
				set.Signup, err = getBool(flags, flag.Name)
			case "auth.method":
				hasAuth = true
			case "shell":
				var shell string
				shell, err = getString(flags, flag.Name)
				set.Shell = convertCmdStrToCmdArray(shell)
			case "create-user-dir":
				set.CreateUserDir, err = getBool(flags, flag.Name)
			case "minimum-password-length":
				set.MinimumPasswordLength, err = getUint(flags, flag.Name)
			case "branding.name":
				set.Branding.Name, err = getString(flags, flag.Name)
			case "branding.color":
				set.Branding.Color, err = getString(flags, flag.Name)
			case "branding.theme":
				set.Branding.Theme, err = getString(flags, flag.Name)
			case "branding.disableExternal":
				set.Branding.DisableExternal, err = getBool(flags, flag.Name)
			case "branding.disableUsedPercentage":
				set.Branding.DisableUsedPercentage, err = getBool(flags, flag.Name)
			case "branding.disableUserProfile":
				set.Branding.DisableUserProfile, err = getBool(flags, flag.Name)
			case "branding.defaultLoginUser":
				set.Branding.DefaultLoginUser, err = getString(flags, flag.Name)
			case "branding.files":
				set.Branding.Files, err = getString(flags, flag.Name)
			case "file-mode":
				set.FileMode, err = getMode(flags, flag.Name)
			case "dir-mode":
				set.DirMode, err = getMode(flags, flag.Name)
			}
		})

		if err != nil {
			return err
		}

		// Get updated config
		auther, err = getSettings(flags, set, ser, auther, false)
		if err != nil {
			return err
		}

		// Save updated config
		err = st.Auth.Save(auther)
		if err != nil {
			return err
		}

		err = st.Settings.Save(set)
		if err != nil {
			return err
		}

		err = st.Settings.SaveServer(ser)
		if err != nil {
			return err
		}

		return printSettings(ser, set, auther)
	}, storeOptions{}),
}
