# Release procedures

When releasing a new version, please ensure the following steps are carried out:


1. Update [CHANGES](CHANGES) to reflect the new updates.
2. Bump version in:
    - bower.json (do this manually by editing bower.json)
    - package.json - do this by running `npm version newversion` - e.g. `npm version 3.17.0`. This will automatically tag and commit the version bump.
3. Push the tag to `intermine/imjs` on github. This might be something like `git push upstream v3.17.0`.
4. Release on [npm](https://docs.npmjs.com/getting-started/publishing-npm-packages). Bower will automatically update to reflect whatever is on master.
5. Update on the [CDN repo](https://github.com/intermine/CDN/tree/master/js/intermine/imjs)
6. Finally - update on the locally hosted InterMine CDN, too!

### Troubleshooting

Alex, Josh, and Yo have access to publish to npm. Speak to one of them to gain full access to publish if you don't have it already. You'll need an account on npmjs.com.
